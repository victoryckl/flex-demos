//    Shine is an MP3 encoder
//    Copyright (C) 1999-2000  Gabriel Bouvigne
//
//    This library is free software; you can redistribute it and/or
//    modify it under the terms of the GNU Library General Public
//    License as published by the Free Software Foundation; either
//    version 2 of the License, or (at your option) any later version.
//
//    This library is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//    Library General Public License for more details.


#include <stdlib.h>

#include "l3bitstream.h" /* the public interface */
#include "l3mdct.h"
#include "l3loop.h"
#include "formatBitstream.h" 
#include "huffman.h"
#include "bitstream.h"
#include "types.h"
#include "tables.h"
#include "error.h"
static bitstream_t *bs = NULL;

BF_FrameData    *frameData    = NULL;
BF_FrameResults *frameResults = NULL;

int PartHoldersInitialized = 0;

BF_PartHolder *headerPH;
BF_PartHolder *frameSIPH;
BF_PartHolder *channelSIPH[ MAX_CHANNELS ];
BF_PartHolder *spectrumSIPH[ MAX_GRANULES ][ MAX_CHANNELS ];
BF_PartHolder *scaleFactorsPH[ MAX_GRANULES ][ MAX_CHANNELS ];
BF_PartHolder *codedDataPH[ MAX_GRANULES ][ MAX_CHANNELS ];
BF_PartHolder *userSpectrumPH[ MAX_GRANULES ][ MAX_CHANNELS ];
BF_PartHolder *userFrameDataPH;

static int encodeSideInfo( side_info_t  *si );
static void encodeMainData(int enc[2][2][samp_per_frame2], side_info_t  *si, scalefac_t   *scalefac );
static void Huffmancodebits( BF_PartHolder **pph, int *ix, gr_info *gi );


void putMyBits( uint32 val, uint16 len )
{
    putbits( bs, val, len );
}

void flush_bitstream()
{
	if (bs != NULL)
	{
		empty_buffer(bs, bs->buf_byte_idx);
	}
}

/*
  format_bitstream()
  
  This is called after a frame of audio has been quantized and coded.
  It will write the encoded audio to the bitstream. Note that
  from a layer3 encoder's perspective the bit stream is primarily
  a series of main_data() blocks, with header and side information
  inserted at the proper locations to maintain framing. (See Figure A.7
  in the IS).
*/

void
format_bitstream( int              enc[2][2][samp_per_frame2],
		      side_info_t  *side,
		      scalefac_t   *scalefac,
		      bitstream_t *in_bs,
		      double           (*xr)[2][samp_per_frame2])
{
    int gr, ch, i;
    bs = in_bs;
    
    if ( frameData == NULL )
    {
	frameData = calloc( 1, sizeof(*frameData) );
    }
    if ( frameResults == NULL )
    {
	frameResults = calloc( 1, sizeof(*frameData) );
    }
    if ( !PartHoldersInitialized )
    {
	headerPH = BF_newPartHolder( 12 );
	frameSIPH = BF_newPartHolder( 12 );

	for ( ch = 0; ch < MAX_CHANNELS; ch++ )
	    channelSIPH[ch] = BF_newPartHolder( 8 );

	for ( gr = 0; gr < MAX_GRANULES; gr++ )	
	    for ( ch = 0; ch < MAX_CHANNELS; ch++ )
	    {
		spectrumSIPH[gr][ch]   = BF_newPartHolder( 32 );
		scaleFactorsPH[gr][ch] = BF_newPartHolder( 64 );
		codedDataPH[gr][ch]    = BF_newPartHolder( samp_per_frame2 );
		userSpectrumPH[gr][ch] = BF_newPartHolder( 4 );
	    }
	userFrameDataPH = BF_newPartHolder( 8 );
	PartHoldersInitialized = 1;
    }

    for ( gr = 0; gr < 2; gr++ )
	for ( ch =  0; ch < config.wave.channels; ch++ )
	{
	    int *pi = &enc[gr][ch][0];
	    double *pr = &xr[gr][ch][0];
	    for ( i = 0; i < samp_per_frame2; i++, pr++, pi++ )
	    {
		if ( (*pr < 0) && (*pi > 0) )
		    *pi *= -1;
	    }
	}

    encodeSideInfo( side );
    encodeMainData( enc, side, scalefac );

   /*
      Put frameData together for the call
      to BitstreamFrame()
    */
    frameData->putbits     = putMyBits;
    frameData->frameLength = config.mpeg.bits_per_frame;
    frameData->nGranules   = 2;
    frameData->nChannels   = config.wave.channels;
    frameData->header      = headerPH->part;
    frameData->frameSI     = frameSIPH->part;

    for ( ch = 0; ch < config.wave.channels; ch++ )
	frameData->channelSI[ch] = channelSIPH[ch]->part;

    for ( gr = 0; gr < 2; gr++ )
	for ( ch = 0; ch < config.wave.channels; ch++ )
	{
	    frameData->spectrumSI[gr][ch]   = spectrumSIPH[gr][ch]->part;
	    frameData->scaleFactors[gr][ch] = scaleFactorsPH[gr][ch]->part;
	    frameData->codedData[gr][ch]    = codedDataPH[gr][ch]->part;
	    frameData->userSpectrum[gr][ch] = userSpectrumPH[gr][ch]->part;
	}
    frameData->userFrameData = userFrameDataPH->part;

    BF_BitstreamFrame( frameData, frameResults );

}


static unsigned slen1_tab[16] = { 0, 0, 0, 0, 3, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4 };
static unsigned slen2_tab[16] = { 0, 1, 2, 3, 0, 1, 2, 3, 1, 2, 3, 1, 2, 3, 2, 3 };

static void encodeMainData(int enc[2][2][samp_per_frame2],
	                   side_info_t  *si,
		           scalefac_t   *scalefac )
{
    int gr, ch, sfb;

    for ( gr = 0; gr < 2; gr++ )
		for ( ch = 0; ch < config.wave.channels; ch++ ){
			scaleFactorsPH[gr][ch]->part->nrEntries = 0;
		    codedDataPH[gr][ch]->part->nrEntries = 0;
		}



	for ( gr = 0; gr < 2; gr++ )
	{
	    for ( ch = 0; ch < config.wave.channels; ch++ )
	    {
		BF_PartHolder **pph = &scaleFactorsPH[gr][ch];		
		gr_info *gi = &(si->gr[gr].ch[ch].tt);
		unsigned slen1 = slen1_tab[ gi->scalefac_compress ];
		unsigned slen2 = slen2_tab[ gi->scalefac_compress ];
		int *ix = &enc[gr][ch][0];

		{
		    if ( (gr == 0) || (si->scfsi[ch][0] == 0) )
			for ( sfb = 0; sfb < 6; sfb++ )
			    *pph = BF_addEntry( *pph,  scalefac->l[gr][ch][sfb], slen1 );

		    if ( (gr == 0) || (si->scfsi[ch][1] == 0) )
			for ( sfb = 6; sfb < 11; sfb++ )
			    *pph = BF_addEntry( *pph,  scalefac->l[gr][ch][sfb], slen1 );

		    if ( (gr == 0) || (si->scfsi[ch][2] == 0) )
			for ( sfb = 11; sfb < 16; sfb++ )
			    *pph = BF_addEntry( *pph,  scalefac->l[gr][ch][sfb], slen2 );
		}
		Huffmancodebits( &codedDataPH[gr][ch], ix, gi );
	    } /* for ch */
	} /* for gr */
} /* main_data */

static unsigned int crc = 0;

static int encodeSideInfo( side_info_t  *si )
{
    int gr, ch, scfsi_band, region, bits_sent;
    
    headerPH->part->nrEntries = 0;
    headerPH = BF_addEntry( headerPH, 0xfff,                          12 );
    headerPH = BF_addEntry( headerPH, config.mpeg.type,               1 );
/* HEADER HARDCODED SHOULDN`T BE THIS WAY ! */
    headerPH = BF_addEntry( headerPH, 1/*config.mpeg.layr*/,          2 );
    headerPH = BF_addEntry( headerPH, !config.mpeg.crc,               1 );
    headerPH = BF_addEntry( headerPH, config.mpeg.bitrate_index,      4 );
    headerPH = BF_addEntry( headerPH, config.mpeg.samplerate_index,   2 );
    headerPH = BF_addEntry( headerPH, config.mpeg.padding,            1 );
    headerPH = BF_addEntry( headerPH, config.mpeg.ext,                1 );
    headerPH = BF_addEntry( headerPH, config.mpeg.mode,               2 );
    headerPH = BF_addEntry( headerPH, config.mpeg.mode_ext,           2 );
    headerPH = BF_addEntry( headerPH, config.mpeg.copyright,          1 );
    headerPH = BF_addEntry( headerPH, config.mpeg.original,           1 );
    headerPH = BF_addEntry( headerPH, config.mpeg.emph,               2 );
    
    bits_sent = 32;

    frameSIPH->part->nrEntries = 0;

    for (ch = 0; ch < config.wave.channels; ch++ )
	channelSIPH[ch]->part->nrEntries = 0;

    for ( gr = 0; gr < 2; gr++ )
	for ( ch = 0; ch < config.wave.channels; ch++ )
	    spectrumSIPH[gr][ch]->part->nrEntries = 0;

	frameSIPH = BF_addEntry( frameSIPH, si->main_data_begin, 9 );

	if ( config.wave.channels == 2 )
	    frameSIPH = BF_addEntry( frameSIPH, si->private_bits, 3 );
	else
	    frameSIPH = BF_addEntry( frameSIPH, si->private_bits, 5 );
	
	for ( ch = 0; ch < config.wave.channels; ch++ )
	    for ( scfsi_band = 0; scfsi_band < 4; scfsi_band++ )
	    {
		BF_PartHolder **pph = &channelSIPH[ch];
		*pph = BF_addEntry( *pph, si->scfsi[ch][scfsi_band], 1 );
	    }

	for ( gr = 0; gr < 2; gr++ )
	    for ( ch = 0; ch < config.wave.channels ; ch++ )
	    {
		BF_PartHolder **pph = &spectrumSIPH[gr][ch];
		gr_info *gi = &(si->gr[gr].ch[ch].tt);
		*pph = BF_addEntry( *pph, gi->part2_3_length,        12 );
		*pph = BF_addEntry( *pph, gi->big_values,            9 );
		*pph = BF_addEntry( *pph, gi->global_gain,           8 );
		*pph = BF_addEntry( *pph, gi->scalefac_compress,     4 );
		*pph = BF_addEntry( *pph, 0, 1 );

		    for ( region = 0; region < 3; region++ )
			*pph = BF_addEntry( *pph, gi->table_select[region], 5 );

		    *pph = BF_addEntry( *pph, gi->region0_count, 4 );
		    *pph = BF_addEntry( *pph, gi->region1_count, 3 );

		*pph = BF_addEntry( *pph, gi->preflag,            1 );
		*pph = BF_addEntry( *pph, gi->scalefac_scale,     1 );
		*pph = BF_addEntry( *pph, gi->count1table_select, 1 );
	    }

	if ( config.wave.channels == 2 )
	    bits_sent += 256;
	else
	    bits_sent += 136;

    return bits_sent;
}




/*
  Note the discussion of huffmancodebits() on pages 28
  and 29 of the IS, as well as the definitions of the side
  information on pages 26 and 27.
  */
static void
Huffmancodebits( BF_PartHolder **pph, int *ix, gr_info *gi )
{
    int huffman_coder_count1( BF_PartHolder **pph, struct huffcodetab *h, int v, int w, int x, int y );
    int bigv_bitcount( int ix[samp_per_frame2], gr_info *cod_info );

    int region1Start;
    int region2Start;
    int i, bigvalues, count1End;
    int v, w, x, y, bits, cbits, xbits, stuffingBits;
    unsigned int code, ext;
    struct huffcodetab *h;
    int bvbits, c1bits, tablezeros, r0, r1, r2, rt, *pr;
    int bitsWritten = 0;
    tablezeros = 0;
    r0 = r1 = r2 = 0;
    
    /* 1: Write the bigvalues */
    bigvalues = gi->big_values <<1;
    {
	    {
                int *scalefac = &sfBandIndex[config.mpeg.samplerate_index+(config.mpeg.type*3)].l[0];
		unsigned scalefac_index = 100;
		
		    scalefac_index = gi->region0_count + 1;
		    region1Start = scalefac[ scalefac_index ];
		    scalefac_index += gi->region1_count + 1;
		    region2Start = scalefac[ scalefac_index ];

		for ( i = 0; i < bigvalues; i += 2 )
		{
		    unsigned tableindex = 100;
		    /* get table pointer */
		    if ( i < region1Start )
		    {
			tableindex = gi->table_select[0];
			pr = &r0;
		    }
		    else
			if ( i < region2Start )
			{
			    tableindex = gi->table_select[1];
			    pr = &r1;
			}
			else
			{
			    tableindex = gi->table_select[2];
			    pr = &r2;
			}
		    h = &ht[ tableindex ];
		    /* get huffman code */
		    x = ix[i];
		    y = ix[i + 1];
		    if ( tableindex )
		    {
			bits = HuffmanCode( tableindex, x, y, &code, &ext, &cbits, &xbits );
			*pph = BF_addEntry( *pph,  code, cbits );
			*pph = BF_addEntry( *pph,  ext, xbits );
			bitsWritten += rt = bits;
			*pr += rt;
		    }
		    else
		    {
			tablezeros += 1;
			*pr = 0;
		    }
		}
	    }
    }
    bvbits = bitsWritten; 

    /* 2: Write count1 area */
    h = &ht[gi->count1table_select + 32];
    count1End = bigvalues + (gi->count1 <<2);
    for ( i = bigvalues; i < count1End; i += 4 )
    {
	v = ix[i];
	w = ix[i+1];
	x = ix[i+2];
	y = ix[i+3];
	bitsWritten += huffman_coder_count1( pph, h, v, w, x, y );
    }
    c1bits = bitsWritten - bvbits;
    if ( (stuffingBits = gi->part2_3_length - gi->part2_length - bitsWritten) )
    {
	int stuffingWords = stuffingBits / 32;
	int remainingBits = stuffingBits % 32;

	/*
	  Due to the nature of the Huffman code
	  tables, we will pad with ones
	*/
	while ( stuffingWords-- )
	    *pph = BF_addEntry( *pph, ~0, 32 );
	if ( remainingBits )
	    *pph = BF_addEntry( *pph, ~0, remainingBits );
	bitsWritten += stuffingBits;
    }
}

int abs_and_sign( int *x )
{
    if ( *x > 0 ) return 0;
    *x *= -1;
    return 1;
}

int huffman_coder_count1( BF_PartHolder **pph, struct huffcodetab *h, int v, int w, int x, int y )
{
    HUFFBITS huffbits;
    unsigned int signv, signw, signx, signy, p;
    int len;
    int totalBits = 0;
    
    signv = abs_and_sign( &v );
    signw = abs_and_sign( &w );
    signx = abs_and_sign( &x );
    signy = abs_and_sign( &y );
    
    p = v + (w << 1) + (x << 2) + (y << 3);
    huffbits = h->table[p];
    len = h->hlen[ p ];
    *pph = BF_addEntry( *pph,  huffbits, len );
    totalBits += len;
    if ( v )
    {
	*pph = BF_addEntry( *pph,  signv, 1 );
	totalBits += 1;
    }
    if ( w )
    {
	*pph = BF_addEntry( *pph,  signw, 1 );
	totalBits += 1;
    }

    if ( x )
    {
	*pph = BF_addEntry( *pph,  signx, 1 );
	totalBits += 1;
    }
    if ( y )
    {
	*pph = BF_addEntry( *pph,  signy, 1 );
	totalBits += 1;
    }
    return totalBits;
}

/* Implements the pseudocode of page 98 of the IS */
int HuffmanCode(int table_select, int x, int y, unsigned int *code, 
                unsigned int *ext, int *cbits, int *xbits )
{
    unsigned signx, signy, linbitsx, linbitsy, linbits, xlen, ylen, idx;
    struct huffcodetab *h;

    *cbits = 0;
    *xbits = 0;
    *code  = 0;
    *ext   = 0;
    
    if(table_select==0) return 0;
    
    signx = abs_and_sign( &x );
    signy = abs_and_sign( &y );
    h = &(ht[table_select]);
    xlen = h->xlen;
    ylen = h->ylen;
    linbits = h->linbits;
    linbitsx = linbitsy = 0;

    if ( table_select > 15 )
    { /* ESC-table is used */
	if ( x > 14 )
	{
	    linbitsx = x - 15;
	    x = 15;
	}
	if ( y > 14 )
	{
	    linbitsy = y - 15;
	    y = 15;
	}

	idx = (x * ylen) + y;
	*code  = h->table[idx];
	*cbits = h->hlen [idx];
	if ( x > 14 )
	{
	    *ext   |= linbitsx;
	    *xbits += linbits;
	}
	if ( x != 0 )
	{
	    *ext <<= 1;
	    *ext |= signx;
	    *xbits += 1;
	}
	if ( y > 14 )
	{
	    *ext <<= linbits;
	    *ext |= linbitsy;
	    *xbits += linbits;
	}
	if ( y != 0 )
	{
	    *ext <<= 1;
	    *ext |= signy;
	    *xbits += 1;
	}
    }
    else
    { /* No ESC-words */
	idx = (x * ylen) + y;
	*code = h->table[idx];
	*cbits += h->hlen[ idx ];
	if ( x != 0 )
	{
	    *code <<= 1;
	    *code |= signx;
	    *cbits += 1;
	}
	if ( y != 0 )
	{
	    *code <<= 1;
	    *code |= signy;
	    *cbits += 1;
	}
    }
    return *cbits + *xbits;
}

