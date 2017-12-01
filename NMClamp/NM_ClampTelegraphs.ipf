#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2017 Jason Rothman
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
//	Contact Jason@ThinkRandom.com
//	www.NeuroMatic.ThinkRandom.com
//
//****************************************************************
//****************************************************************
//
//	NeuroMatic Clamp tab for data acquisition
//
//	Created in the Laboratory of Dr. Angus Silver
//	NPP Department, UCL, London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 July 2003
//
//****************************************************************
//****************************************************************

Constant NM_Axopatch_Beta = 1 // beta setting on Axopath 200A or 200B or 1D
Constant NM_ClampTelegraphSamplesToRead = 20
Constant NM_MultiClampUseLongNames = 0 // ( 0 ) short names ( 1 ) long names
//Constant NM_MultiClampTelegraphWhile = 0 // NOT USED ( 0 ) read gain setting once before acquisition starts ( 1 ) read immediately after recording each wave

StrConstant NM_ClampTelegraphInstrumentList = "Axopatch200A;Axopatch200B;Axopatch1D;MultiClamp700;Dagan3900A;AlembicVE2;"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphPrompt( type )
	String type // "Mode" or "Freq" or "Cap"

	String name, modeStr, tdf = NMClampTabDF
	
	Variable config = ConfigsTabIOnum()
	String instr = StrVarOrDefault( tdf+"TelegraphInstrument", "" )
	String instrList = NM_ClampTelegraphInstrumentList
	
	instrList = RemoveFromList( "MultiClamp700", instrList )

	Prompt instr "telegraphed instrument:", popup instrList
	
	DoPrompt "Telegraph " + type, instr
	
	if ( V_flag == 1 )
		return ""
	endif
	
	name = "T" + type + "_" + instr[ 0, 2 ]

	modeStr = ClampTelegraphStr( type, instr )
	
	ClampBoardNameSet( "ADC", config, name )
	ClampBoardUnitsSet( "ADC", config, "V" )
	ClampBoardScaleSet( "ADC", config, 1 )
	
	SetNMstr( tdf+"TelegraphInstrument", instr )
	
	return modeStr
	
End // ClampTelegraphPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainPrompt()

	Variable board, chan, output
	String name, chanStr, modeStr = ""
	
	String tdf = NMClampTabDF, cdf = NMClampDF

	Variable config = ConfigsTabIOnum()
	String instr = StrVarOrDefault( tdf+"TelegraphInstrument", "" )
	String blist = StrVarOrDefault( cdf+"BoardList", "" )

	Prompt instr "telegraphed instrument:", popup NM_ClampTelegraphInstrumentList
	
	DoPrompt "Telegraph Gain", instr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( tdf+"TelegraphInstrument", instr )
	
	if ( StringMatch( instr, "MultiClamp700" ) == 1 )
	
		chan = 1
		output = 1
		
		Prompt chan "this ADC input is connected to channel:", popup "1;2;"
		Prompt output " ", popup "primary output;secondary output;"
		
		DoPrompt "MultiClamp700 Telegraph Gain", chan, output
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		return ClampTGainStrMultiClamp( chan, output )
	
	endif
	
	Prompt chan "ADC input channel to scale:"
	Prompt board "on board number:", popup blist
	
	if ( ItemsInList( blist ) > 1 )
		DoPrompt instr + " Telegraph Gain", chan, board
	else
		DoPrompt instr + " Telegraph Gain", chan
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	name = "TGain_" + instr[ 0, 2 ]

	modeStr = ClampTGainStr( board, chan, instr )
	
	ClampBoardNameSet( "ADC", config, name )
	ClampBoardUnitsSet( "ADC", config, "V" )
	ClampBoardScaleSet( "ADC", config, 1 )
	
	SetNMstr( tdf+"TelegraphInstrument", instr )
	
	return modeStr
	
End // ClampTGainPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphStr( select, instrument )
	String select // "Mode", "Freq", "Cap" (see ClampTGrainStr below)
	String instrument
	
	return "T" + select + "=" + instrument
	
End // ClampTelegraphStr

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTelegraphCheck( select, modeStr )
	String select // "Gain", "Mode", "Freq", "Cap"
	String modeStr
	
	String findStr = "T" + select + "="
	
	if ( strsearch( modeStr, findstr, 0, 2 ) >= 0 )
		return 1
	endif
	
	return 0
	
End // ClampTelegraphCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphInstrument( modeStr )
	String modeStr
	
	Variable icnt
	String instrument, instrList
	
	instrList = NM_ClampTelegraphInstrumentList
	
	for ( icnt = 0 ; icnt < ItemsInList( instrList ) ; icnt += 1 )
	
		instrument = StringFromList( icnt, instrList )
		
		if ( strsearch( modeStr, instrument, 0, 2 ) > 0 )
			return instrument
		endif
		
	endfor
	
	return ""
	
End // ClampTelegraphInstrument

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTelegraphStrShort( modeStr )
	String modeStr
	
	Variable icnt
	String bname, blist = NM_ClampTelegraphInstrumentList
	
	if ( StringMatch( modeStr[ 0, 0 ], "T" ) == 0 )
		return "" // wrong format
	endif
	
	if ( strsearch( modeStr, "=", 0 ) < 0 )
		return "" // wrong format
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( blist ) ; icnt += 1 )
		bname = StringFromList( icnt, blist )
		modeStr = ReplaceString( bname, modeStr, bname[ 0, 2 ] )
	endfor
	
	return modeStr

End // ClampTelegraphStrShort

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTelegraphAuto()

	TModeAuto()
	TCapAuto()
	TFreqAuto()

End // ClampTelegraphAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainStr( board, chan, instrument )
	Variable board
	Variable chan
	String instrument
	
	if ( ( numtype( board ) > 0 ) || ( board < 0 ) )
		board = 0
	endif
	
	if ( ( numtype( chan ) > 0 ) || ( chan < 0 ) )
		chan = Nan
	endif
	
	return "TGain=B" + num2istr( board ) + "_C" + num2istr( chan ) + "_" + instrument
	
End // ClampTGainStr

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainStrSearch( modeStr, searchStr )
	String modeStr
	String searchStr
	
	Variable icnt, jcnt, slen = strlen( searchStr )
	
	icnt = strsearch( modeStr, searchStr, 0, 2 )
	
	if ( icnt < 0 )
		return Nan
	endif
	
	icnt += slen
	
	jcnt = strsearch( modeStr, "_", icnt )
	
	if ( jcnt < 0 )
		return Nan
	endif
	
	return str2num( modeStr[ icnt, jcnt - 1 ] )
	
End // ClampTGainStrSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainBoard( modeStr )
	String modeStr
	
	return ClampTGainStrSearch( modeStr, "=B" )
	
End // ClampTGainBoard

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainChan( modeStr )
	String modeStr
	
	Variable chan = ClampTGainStrSearch( modeStr, "_C" )
	
	if ( numtype( chan ) > 0 )
		chan = ClampTGainStrSearch( modeStr, "=C" )
	endif
	
	return chan
	
End // ClampTGainChan

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainConfigNameList()

	Variable icnt
	String nlist = "", cdf = NMClampDF
	
	String TGainList = StrVarOrDefault( cdf+"TGainList", "" )
	
	for ( icnt = 0; icnt < ItemsInList( TGainList ); icnt += 1 )
		nlist = AddListItem( "TGain_" + num2istr( icnt ), nlist, ";", inf )
	endfor
	
	return nlist

End // ClampTGainConfigNameList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainInstrumentFind( config )
	Variable config
	
	String modeStr
	
	String bdf = NMStimBoardDF( "" )

	if ( WaveExists( $bdf+"ADCmode" ) && ( config >= 0 ) && ( config < numpnts( $bdf+"ADCmode" ) ) )
	
		Wave /T ADCmode = $bdf+"ADCmode"
		
		modeStr = ADCmode[ config ]
		
		if ( ClampTelegraphCheck( "Gain", modeStr ) == 1 )
			return ClampTelegraphInstrument( modeStr )
		endif
		
	endif
	
	return ""

End // ClampTGainInstrumentFind

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainConfigEditOld( config )
	Variable config
	
	Variable gchan, achan, icnt, kill = 1
	String item, instr, newList = "", cdf = NMClampDF
	
	String TGainList = StrVarOrDefault( cdf+"TGainList", "" )
	
	item = StringFromList( config, TGainList )
	
	if ( strlen( item ) == 0 )
		return -1
	endif
	
	gchan = str2num( StringFromList( 0, item, "," ) )
	achan = str2num( StringFromList( 1, item, "," ) )
	instr = StringFromList( 2, item, "," )
	
	Prompt gchan, "ADC input channel to read telegraph gain:"
	Prompt achan, "ADC input channel to scale:"
	Prompt instr, "telegraphed instrument:", popup NM_ClampTelegraphInstrumentList
	Prompt kill, "or delete this telegraph configuration:", popup "no;yes;"
	
	DoPrompt "ADC Telegraph Gain Config " + num2istr( config ), gchan, achan, instr, kill
		
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	for ( icnt = 0; icnt < ItemsInList( TGainList ); icnt += 1 )
		
		if ( icnt == config )
		
			if ( kill == 2 )
				continue
			endif
			
			item = num2istr( gchan ) + "," + num2istr( achan ) + "," + instr
			
		else
		
			item = StringFromList( icnt, TGainList )
			
		endif
		
		newList = AddListItem( item, newList, ";", inf )
	
	endfor
	
	SetNMstr( cdf+"TGainList", newList )

End // ClampTGainConfigEditOld

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainValue( df, config, wavePoint )
	String df // data folder
	Variable config
	Variable wavePoint // wave point number, or ( -1 ) to compute the average of all points
	
	Variable npnts
	
	String wname = df + "CT_TGain" + num2istr( config ) // telegraph gain wave
	
	if ( WaveExists( $wname ) == 0 )
		return Nan // -1
	endif
	
	Wave temp = $wname

	if ( wavePoint == -1 ) // return avg of wave
		temp = Zero2Nan( temp ) // remove possible 0's
		WaveStats /Q temp
		return V_avg
	elseif ( ( wavePoint >= 0 ) && ( wavePoint < numpnts( temp ) ) )
		return temp[ wavePoint ]
	else
		return NaN // -1
	endif

End // ClampTGainValue

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainScaleValue( bdf )
	String bdf
	
	Variable config, tgainChan, tgainv, scale, tscale
	String modeStr, instr
	
	if ( !WaveExists( $bdf+"ADCtgain" ) )
		return NaN
	endif
	
	Wave ADCscale = $bdf+"ADCscale"
	Wave ADCchan = $bdf+"ADCchan"
	Wave ADCtgain = $bdf+"ADCtgain"
	Wave /T ADCmode = $bdf+"ADCmode"
		
	for ( config = 0 ; config < numpnts( ADCtgain ) ; config += 1 )
	
		if ( numtype( ADCtgain[config] ) == 0 )
		
			if ( ( numtype( ADCchan[config] ) > 0 ) || ( numtype( ADCtgain[config] ) > 0 ) )
				continue
			endif
			
			modeStr = ADCmode[ADCtgain[config]]
			tgainChan = ClampTGainChan( modeStr )
			tgainv = ClampTgainValue( GetDataFolder( 1 ), tgainChan, -1 )
			scale = ADCscale[config]
			
			if ( ( numtype( tgainv ) == 0 ) && ( tgainv >= 0 ) )
			
				SetNMvar( "CT_Tgain"+num2istr( tgainChan )+"_avg", tgainv ) // save in data folder
				instr = ClampTelegraphInstrument( modeStr )
				tscale = MyTelegraphGain( tgainv, scale, instr )
				
				if ( ( numtype( tscale ) == 0 ) && ( tscale > 0 ) )
					ADCscale[config] = tscale
				endif
				
			endif
			
		endif
		
	endfor
	
	return NaN
	
End // ClampTGainScaleValue

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTGainConvert() // convert final TGain values to scale values
	Variable ocnt, icnt, tvalue, npnts, chan, gchan, achan
	String olist, oname, item
	
	String instr, cdf = NMClampDF
	
	String TGainList = StrVarOrDefault( cdf+"TGainList", "" )
	String instrOld = StrVarOrDefault( cdf+"ClampInstrument", "" )
	
	olist = WaveList( "CT_TGain*", ";", "" ) // created by NIDAQ code
	
	if ( ItemsInList( TGainList ) <= 0 )
		return 0
	endif
	
	for ( ocnt = 0; ocnt < ItemsInList( olist ); ocnt += 1 )
	
		oname = StringFromList( ocnt, olist )
		chan = str2num( oname[ 8, inf ] )
		
		instr = ""
		
		for ( icnt = 0; icnt < ItemsInList( TGainList ); icnt += 1 )
		
			item = StringFromList( icnt, TGainList )
			gChan = str2num( StringFromList( 0, item, "," ) ) // corresponding telegraph ADC input channel
			aChan = str2num( StringFromList( 1, item, "," ) ) // ADC input channel
			
			if ( chan == aChan )
				instr = StringFromList( 2, item, "," )
			endif
			
		endfor
		
		if ( strlen( instr ) == 0 )
			instr = instrOld
		endif
		
		Wave wtemp = $oname
		
		npnts = numpnts( wtemp )
		
		for ( icnt = 0; icnt < npnts; icnt += 1 )
		
			tvalue = wtemp[ icnt ]
			
			if ( ( numtype( tvalue ) == 0 ) && ( tvalue > 0 ) )
				wtemp[ icnt ] = MyTelegraphGain( tvalue, tvalue, instr )
			endif
			
		endfor
	
	endfor
	
	olist = VariableList( "CT_TGain*", ";", 4+2 ) // created by ITC code
	
	for ( ocnt = 0; ocnt < ItemsInList( olist ); ocnt += 1 )
	
		oname = StringFromList( ocnt, olist )
		
		tvalue = NumVarOrDefault( oname, -1 )
		
		chan = str2num( oname[ 5, inf ] )
		
		instr = ""
		
		for ( icnt = 0; icnt < ItemsInList( TGainList ); icnt += 1 )
		
			item = StringFromList( icnt, TGainList )
			gChan = str2num( StringFromList( 0, item, "," ) ) // corresponding telegraph ADC input channel
			aChan = str2num( StringFromList( 1, item, "," ) ) // ADC input channel
			
			if ( chan == aChan )
				instr = StringFromList( 2, item, "," )
			endif
			
		endfor
		
		if ( strlen( instr ) == 0 )
			instr = instrOld
		endif
		
		if ( tvalue == -1 )
			continue
		endif
		
		SetNMvar( oname, MyTelegraphGain( tvalue, tvalue, instr ) )
		
	endfor

End // ClampTGainConvert

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTelegraphGain( TGain, defaultTGain, instrument ) // see NIDAQ code for example call
	Variable TGain // telegraphed value
	Variable defaultTGain // default gain value
	String instrument // instrument name
	
	Variable scale, alpha = -1, gain = defaultTGain
	
	if ( ( numtype( TGain ) == 0 ) && ( TGain > 0 ) )
	
		strswitch( instrument )
		
			case "Axopatch200A":
			case "Axopatch200B":
				alpha = TGainAxopatch200( TGain )
				scale = 0.001 * NM_Axopatch_Beta // V / mV
				break
				
			case "Axopatch1D":
				alpha = TGainAxopatch1D( TGain )
				scale = 0.001 * NM_Axopatch_Beta // V / mV
				break
				
			case "Dagan3900A":
				alpha = TGainDagan3900A( TGain )
				scale = 0.001
				break
				
			case "AlembicVE2":
				alpha = TGainAlembicVE2( TGain )
				scale = 0.001
				break
				
			default:
				alpha = -1
				
		endswitch
		
		if ( ( alpha > 0 ) && ( numtype( alpha ) == 0 ) )
			gain = alpha * scale
		endif
	
	endif
	
	NMNotesFileVar( "F_TGain", gain )
	
	return gain
	
End // MyTelegraphGain

//****************************************************************
//****************************************************************
//****************************************************************

Function TGainAxopatch200( telValue ) // Axopatch 200 (A or B) telegraph gain look-up table
	Variable telValue
	
	Variable tv = 5 * round( 10 * telValue / 5 ) // multiply by 10 and round to nearest multiple of 5
	
	switch( tv )
		case 5:
			return 0.05
		case 10:
			return 0.1
		case 15:
			return 0.2
		case 20:
			return 0.5
		case 25:
			return 1
		case 30:
			return 2
		case 35:
			return 5
		case 40:
			return 10
		case 45:
			return 20
		case 50:
			return 50
		case 55:
			return 100
		case 60:
			return 200
		case 65:
			return 500
		default:
			Print NMCR + "Axopatch 200 Telegraph Gain not recognized : " + num2str( telValue )
	endswitch
	
	return -1

End // TGainAxopatch200

//****************************************************************
//****************************************************************
//****************************************************************

Function TGainAxopatch1D( telValue ) // Axopatch 1D telegraph gain look-up table
	Variable telValue
	
	Variable tv = 4 * round( 10 * telValue / 4 ) // multiply by 10 and round to nearest multiple of 4
	
	switch( tv )
		case 4:
			return 0.5
		case 8:
			return 1
		case 12:
			return 2
		case 16:
			return 5
		case 20:
			return 10
		case 24:
			return 20
		case 28:
			return 50
		case 32:
			return 100
		default:
			Print NMCR + "Axopatch 1D Telegraph Gain not recognized : " + num2str( telValue )
	endswitch
	
	return -1

End // TGainAxopatch1D

//****************************************************************
//****************************************************************
//****************************************************************

Function TGainAlembicVE2( telValue ) // TGainAlembic VE2 telegraph gain look-up table
	Variable telValue
	
	Variable tv = 5 * round( 10 * telValue / 5 ) // multiply by 10 and round to nearest multiple of 5
	
	switch( tv )
		case 5:
			return 0.05
		case 10:
			return 0.1
		case 15:
			return 0.2
		case 20:
			return 0.5
		case 25:
			return 1
		case 30:
			return 2
		case 35:
			return 5
		default:
			Print NMCR + "Alembic VE2 Telegraph Gain not recognized : " + num2str( telValue )
	endswitch
	
	return -1

End // TGainAlembicVE2

//****************************************************************
//****************************************************************
//****************************************************************

Function TGainDagan3900A( telValue ) // Dagan 3900A telegraph gain look-up table
	Variable telValue
	
	Variable tv = round( telValue / 0.405 )	
	
	switch( tv )
		case 1:
			return 1
		case 2:
			return 2
		case 3:
			return 5
		case 4:
			return 10
		case 5:
			return 20
		case 6:
			return 50
		case 7:
			return 100
		case 8:
			return 500
		default:
			Print NMCR + "Dagan 3900A Telegraph Gain not recognized : " + num2str( telValue )
	endswitch
	
	return -1

End // TGainDagan3900A

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Telegraph Mode Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function TModeAuto()

	Variable wcnt, bcnt, icnt, found
	
	String instr, tmode, ndf = NMNotesDF
	String bname, blist = NM_ClampTelegraphInstrumentList
	String wname, wlist = WaveList("CT_TMode*",";","")
	
	if ( exists( ndf + "F_TMode" ) == 2 )
		NMNotesFileStr("F_TMode", "") // clear existing note variables
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wlist ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		icnt = strlen( wname )
		instr = wname[ icnt-3, icnt-1 ]
		
		found = 0
		
		for ( bcnt = 0 ; bcnt < ItemsInList( blist ) ; bcnt += 1 )
		
			bname = StringFromList( bcnt, blist )
			
			if ( StringMatch( instr, bname[ 0, 2 ] ) == 1 )
				instr = bname
				found = 1
				break
			endif
			
		endfor
		
		if ( found == 0 )
			continue
		endif
		
		WaveStats /Q $wname
		
		tmode = ""
		
		strswitch( instr )
	
			case "Axopatch200A":
			case "Axopatch200B":
				tmode = TModeAxopatch200(V_avg)
				break
			
		endswitch
		
		SetNMstr(wname+"_Setting", tmode )
		NMNotesFileStr("F_TMode", tmode)
	
	endfor

End // TModeAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheck(mode) // check acquisition telegraph mode is set correctly
	Variable mode // (-1) kill (0) run (1) config (2) init
	
	String tmode, mode1, mode2, sdf = StimDF()
	
	String instr = StrVarOrDefault(sdf+"TModeInstrument", "")
	String amode = StrVarOrDefault(sdf+"TModeStr", "")
	
	String strName = "CT_TMode_" + instr[ 0, 2 ] + "_Setting" // output string from TModeAuto
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			TModeCheckConfig()
			return 0
			
		case 2:
		case -1:
		default:
			return 0
			
	endswitch
	
	if ( StringMatch( instr, "MultiClamp700" ) == 1 )
		
		if ( NMMultiClampTModeCheck( amode ) != 0 )
			return -1
		endif
		
	endif
	
	if ( exists( strName ) == 2 )
		
		tmode = StrVarOrDefault( strName, "" )
		
		if ( ( strlen( tmode ) > 0 ) && ( StringMatch( amode, tmode ) == 0 ) )
			ClampError(1, "acquisition mode should be " + amode)
			return -1
		endif
	
	endif
	
	return 0
	
End // TModeCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheckConfig()
	
	String cdf = NMClampDF, sdf = StimDF()
	String select1, select2, mlist = ""
	
	String instr = StrVarOrDefault(sdf+"TModeInstrument", "")
	String tmode = StrVarOrDefault(sdf+"TModeStr", "")
	
	Prompt instr, "telegraphed instrument:", popup NM_ClampTelegraphInstrumentList
	
	DoPrompt "Check Telegraph Mode", instr
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMstr(sdf+"TModeInstrument", instr)
	
	mlist = TModeList( instr )
	
	if ( StringMatch( instr, "MultiClamp700" ) == 1 )
	
		select1 = StringFromList( 0, tmode )
		select2 = StringFromList( 1, tmode )
		
		Prompt select1, "select mode required for channel 1:", popup mlist
		Prompt select2, "select mode required for channel 2:", popup mlist
		DoPrompt "Check Telegraph Mode", select1, select2
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
		tmode = select1 + ";" + select2 + ";"
	
	else
	
		Prompt tmode, "select mode required for this protocol:", popup mlist
		DoPrompt "Check Telegraph Mode", tmode
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
	endif
	
	SetNMstr(sdf+"TModeStr", tmode)

End // TModeCheckConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheckOld(mode) // check acquisition telegraph mode is set correctly
	Variable mode // (-1) kill (0) run (1) config (2) init
	
	Variable telValue
	String tmode, cdf = NMClampDF, sdf = StimDF()
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			TModeCheckConfig()
			return 0
			
		case 2:
		case -1:
		default:
			return 0
			
	endswitch
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	Variable chan = NumVarOrDefault(cdf+"TModeChan", -1)
	String amode = StrVarOrDefault(sdf+"TModeStr", "")
	String instr = StrVarOrDefault(cdf+"ClampInstrument", "")
	
	if (chan < 0)
		return -1
	endif
	
	telValue = ClampReadManager(StrVarOrDefault(cdf+"AcqBoard", ""), driver, chan, 1, 5)
	tmode = TModeAxopatch200(telValue)
	
	strswitch(instr)
	
		case "Axopatch200A":
		case "Axopatch200B":
		
			if (StringMatch(amode, "I-Clamp") == 1)
				if (StringMatch(tmode[ 0, 0 ], "I") == 1)
					tmode = "I-Clamp"
				endif
			endif
			
			if (StringMatch(amode, tmode) == 0)
				ClampError(1, "acquisition mode should be " + amode)
				return -1
			endif
			
			break
			
	endswitch
	
	String /G TModeStr = amode
	
End // TModeCheckOld

//****************************************************************
//****************************************************************
//****************************************************************

Function TModeCheckConfigOld()

	String cdf = NMClampDF, sdf = StimDF()
	
	Variable board = NumVarOrDefault(cdf+"TModeBoard", 0)
	Variable chan = NumVarOrDefault(cdf+"TModeChan", 0)
	
	String instr = StrVarOrDefault(cdf+"TModeInstrument", "")
	String amode = StrVarOrDefault(sdf+"TModeStr", "")
	
	String mlist = "V-Clamp;I-Clamp;I-Clamp Normal;I-Clamp Fast;"
	
	Prompt chan, "select ADC input that reads telegraph mode:", popup "0;1;2;3;4;5;6;7;"
	Prompt amode, "select mode required for this protocol:", popup mlist
	Prompt instr, "telegraphed instrument:", popup "Axopatch200A;Axopatch200B;"
	
	DoPrompt "Check Telegraph Mode", chan, amode, instr
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMvar(cdf+"TModeChan", chan-1)
	SetNMstr(sdf+"TModeStr", amode)

End // TModeCheckConfigOld

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TModeList( device )
	String device // e.g. "Axopatch200B"
	
	strswitch( device )
	
		case "Axopatch200A":
		case "Axopatch200B":
			return "V-Clamp;I-Clamp;I-Clamp Normal;I-Clamp Fast;"
			
		case "MultiClamp700":
			return "Dont Care;V-Clamp;I-Clamp;"
			
	endswitch
	
	return ""

End // TModeList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TModeAxopatch200( telValue ) // Axopatch 200 (A or B) telegraph mode look-up table
	Variable telValue
	
	Variable tv = round( telValue )
	
	switch( tv )
		case 4:
			return "Track"
		case 6:
			return "V-Clamp"
		case 3: // B only
			return "I = 0"
		case 2:
			return "I-Clamp Normal"
		case 1:
			return "I-Clamp Fast"
		default:
			Print NMCR + "Axopatch 200 Telegraph Mode not recognized : " + num2str( telValue )
	endswitch
	
	return "Mode Not Recognized"

End // TModeAxopatch200

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Telegraph Capacitance Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function TCapAuto()

	Variable wcnt, bcnt, icnt, found, cap
	
	String instr, ndf = NMNotesDF
	String bname, blist = NM_ClampTelegraphInstrumentList
	String wname, wlist = WaveList("CT_TCap*",";","")
	
	if ( exists( ndf + "F_TCap" ) == 2 )
		NMNotesFileVar("F_TCap", Nan) // clear existing note variables
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wlist ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		icnt = strlen( wname )
		instr = wname[ icnt-3, icnt-1 ]
		
		found = 0
		
		for ( bcnt = 0 ; bcnt < ItemsInList( blist ) ; bcnt += 1 )
		
			bname = StringFromList( bcnt, blist )
			
			if ( StringMatch( instr, bname[ 0, 2 ] ) == 1 )
				instr = bname
				found = 1
				break
			endif
			
		endfor
		
		if ( found == 0 )
			continue
		endif
		
		WaveStats /Q $wname
		
		cap = Nan
		
		strswitch( instr )
	
			case "Axopatch200A":
			case "Axopatch200B":
				cap = TCapAxopatch200(V_avg)
				break
			
		endswitch
		
		SetNMvar(wname+"_Setting", cap )
		NMNotesFileVar("F_TCap", cap)
	
	endfor

End // TCapAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function TCapAxopatch200( telValue ) // Axopatch 200 (A or B) telegraph cell capacitance look-up table
	Variable telValue
	
	if ( telValue < 0 )
		Print NMCR + "Axopatch 200 Telegraph Capacitance : Whole Cell Capacitance is switched OFF"
		return Nan
	endif
	
	if ( telValue > 10 )
		Print NMCR + "Axopatch 200 Telegraph Capacitance not recognized : " + num2str( telValue )
		return Nan
	endif
	
	if ( NM_Axopatch_Beta == 1 )
		return telValue * 10 // 0 - 100 pF
	elseif ( NM_Axopatch_Beta == 0.1 )
		return telValue * 100 // range 0 - 1000 pF
	else
		Print NMCR + "Axopatch 200 Telegraph Capacitance not recognized : " + num2str( telValue )
		return Nan
	endif

End // TCapAxopatch200

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Telegraph Frequency Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function TFreqAuto()

	Variable wcnt, bcnt, icnt, found, freq
	
	String instr, ndf = NMNotesDF
	String bname, blist = NM_ClampTelegraphInstrumentList
	String wname, wlist = WaveList("CT_TFreq*",";","")
	
	if ( exists( ndf + "F_TFreq" ) == 2 )
		NMNotesFileVar("F_TFreq", Nan) // clear existing note variables
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wlist ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		icnt = strlen( wname )
		instr = wname[ icnt-3, icnt-1 ]
		
		found = 0
		
		for ( bcnt = 0 ; bcnt < ItemsInList( blist ) ; bcnt += 1 )
		
			bname = StringFromList( bcnt, blist )
			
			if ( StringMatch( instr, bname[ 0, 2 ] ) == 1 )
				instr = bname
				found = 1
				break
			endif
			
		endfor
		
		if ( found == 0 )
			continue
		endif
		
		WaveStats /Q $wname
		
		freq = Nan
		
		strswitch( instr )
		
			case "Axopatch200A":
				freq = TFreqAxopatch200A(V_avg)
				break
	
			case "Axopatch200B":
				freq = TFreqAxopatch200B(V_avg)
				break
				
			case "Axopatch1D":
				freq = TFreqAxopatch1D(V_avg)
				break
			
		endswitch
		
		SetNMvar(wname+"_Setting", freq )
		NMNotesFileVar("F_TFreq", freq)
	
	endfor

End // TFreqAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function TFreqAxopatch200A( telValue ) // Axopatch 200A telegraph frequency look-up table
	Variable telValue
	
	Variable tv = 2 * round( telValue / 2 )
	
	switch( tv )
		case 2:
			return 1
		case 4:
			return 2
		case 6:
			return 5
		case 8:
			return 10
		case 10:
			return 50
		default:
			Print NMCR + "Axopatch 200A Telegraph Frequency not recognized : " + num2str( telValue )
	endswitch
	
	return Nan

End // TFreqAxopatch200A

//****************************************************************
//****************************************************************
//****************************************************************

Function TFreqAxopatch200B( telValue ) // Axopatch 200B telegraph frequency look-up table
	Variable telValue
	
	Variable tv = 2 * round( telValue / 2 )
	
	switch( tv )
		case 2:
			return 1
		case 4:
			return 2
		case 6:
			return 5
		case 8:
			return 10
		case 10:
			return 100
		default:
			Print NMCR + "Axopatch 200B Telegraph Frequency not recognized : " + num2str( telValue )
	endswitch
	
	return Nan

End // TFreqAxopatch200B

//****************************************************************
//****************************************************************
//****************************************************************

Function TFreqAxopatch1D( telValue ) // Axopatch 1D telegraph frequency look-up table
	Variable telValue
	
	Variable tv = 4 * round( 10 * telValue / 4 )
	
	if ( tv < 0 )
	
		Print NMCR + "Axopatch 1D Telegraph Frequency : bypass on"
	
		return NaN
	
	endif
	
	switch( tv )
		case 4:
			return 20 // Hz
		case 8:
			return 50
		case 12:
			return 100
		case 16:
			return 200
		case 20:
			return 500
		case 24:
			return 1000
		case 28:
			return 2000
		case 32:
			return 5000
		case 36:
			return 10000
		case 40:
			return 20000
		case 44:
			return 50000
		case 48:
			return 100000
		default:
			Print NMCR + "Axopatch 1D Telegraph Frequency not recognized : " + num2str( telValue )
	endswitch
	
	return Nan

End // TFreqAxopatch1D

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Telegraph Functions for MultiClamp700 amplifier
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampAxonTelegraphAlert()

End // NMClampAxonTelegraphAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTGainStrMultiClamp( chan, output )
	Variable chan // 1 or 2
	Variable output // 1 ( primary ) or 2 ( secondary )
	
	if ( chan != 2 )
		chan = 1
	endif
	
	if ( output != 2 )
		output = 1
	endif
	
	return "TGain=C" + num2istr( chan ) + "_O" + num2istr( output ) + "_MultiClamp700"
	
End // ClampTGainStrMultiClamp

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampVarList( output )
	Variable output // ( 0 ) both ( 1 ) primary ( 2 ) secondary
	
	String strList0 = "OperatingMode;HardwareType;ExtCmdSens;MembraneCap;SeriesResistance;"
	String strList1 = "ScaledOutSignal;ScaleFactorUnits;ScaleFactor;Alpha;LPFCutoff;"
	String strList2 = "RawOutSignal;RawScaleFactorUnits;RawScaleFactor;SecondaryAlpha;SecondaryLPFCutoff;"
	
	switch( output )
		case 0:
			return strList0 + strList1 + strList2
		case 1:
			return strList0 + strList1
		case 2:
			return strList0 + strList2
	endswitch
	
	return ""
	
End // NMMultiClampVarList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampStrVarList( output )
	Variable output // ( 0 ) both ( 1 ) primary ( 2 ) secondary
	
	String strList0 = "OperatingMode;HardwareType;"
	String strList1 = "ScaledOutSignal;ScaleFactorUnits;"
	String strList2 = "RawOutSignal;RawScaleFactorUnits;"
	
	switch( output )
		case 0:
			return strList0 + strList1 + strList2
		case 1:
			return strList0 + strList1
		case 2:
			return strList0 + strList2
	endswitch
	
	return ""

End // NMMultiClampStrVarList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampServerWave()

	return NMClampDF + "W_TelegraphServers"

End // NMMultiClampServerWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampServersCheck()

	Variable numServers
	String saveDF, cdf = NMClampDF
	
	String wname = NMMultiClampServerWave()
	
	if ( exists( "AxonTelegraphFindServers" ) != 4 ) // no XOP
		return -1
	endif
	
	if ( WaveExists( $wname ) == 1 )
		
		numServers = DimSize( $wname, 0 )
		
		if ( numServers > 0 )
			return 0
		endif
		
	endif
	
	if ( DataFolderExists( cdf ) == 0 )
		return -1
	endif
	
	saveDF = GetDataFolder( 1 )
	
	SetDataFolder $cdf

	try
		Execute /Q/Z "AxonTelegraphFindServers /Z";AbortOnRTE
	catch
		//print GetRTErrMessage()
	endtry
	
	SetDataFolder $saveDF
	
	if ( WaveExists( $wname ) == 1 )
		
		numServers = DimSize( $wname, 0 )
		
		if ( numServers > 0 )
			return 0
		endif
		
	endif
	
	return -1
	
End // NMMultiClampServersCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphMode( modeStr )
	String modeStr
	
	Variable chanNum, output
	String cdf = NMClampDF
	
	//if ( NumVarOrDefault( cdf+"DemoMode", 0 ) )
	//	return 0
	//endif
	
	if ( strsearch( modeStr, "MultiClamp700", 0, 2 ) < 0 )
		return 0 // NO
	endif
	
	chanNum = ClampTGainStrSearch( modeStr, "=C" )
	output = ClampTGainStrSearch( modeStr, "_O" )
		
	if ( ( chanNum != 1 ) && ( chanNum != 2 ) )
		DoAlert 0, "MultiClamp Telegraph Error: bad channel number: " + num2istr( chanNum )
		return 0
	endif
	
	if ( ( output != 1 ) && ( output != 2 ) )
		DoAlert 0, "MultiClamp Telegraph Error: bad output number: " + num2istr( output )
		return 0
	endif

	return 1 // YES

End // NMMultiClampTelegraphMode

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampADCScaleCall( modeStr )
	String modeStr
	
	Variable chanNum, output

	if ( NMMultiClampTelegraphMode( modeStr ) == 0 )
		return Nan
	endif
	
	chanNum = ClampTGainStrSearch( modeStr, "=C" )
	output = ClampTGainStrSearch( modeStr, "_O" )
	
	return NMMultiClampADCScale( chanNum, output )

End // NMMultiClampADCScaleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampADCScale( chanNum, output )
	Variable chanNum // 1 or 2
	Variable output // 1 - primary, 2 - secondary
	
	Variable scale, alpha
	
	switch( output )
	
		case 1:
		
			scale = NMMultiClampValue( chanNum, "ScaleFactor" )
			alpha = NMMultiClampValue( chanNum, "Alpha" )
			
			return scale * alpha
			
		case 2:
		
			scale = NMMultiClampValue( chanNum, "RawScaleFactor" )
			alpha = NMMultiClampValue( chanNum, "SecondaryAlpha" )
		
			return scale * alpha
			
	endswitch
	
	return Nan
	
End // NMMultiClampADCScale

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampUnits( chanNum, output )
	Variable chanNum // 1 or 2
	Variable output // 1 - primary, 2 - secondary
	
	switch( output )
		case 1:
			return NMMultiClampStrValue( chanNum, "ScaleFactorUnits", NM_MultiClampUseLongNames )
		case 2:
			return NMMultiClampStrValue( chanNum, "RawScaleFactorUnits", NM_MultiClampUseLongNames )
	endswitch
	
	return ""
	
End // NMMultiClampUnits

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampSignal( chanNum, output )
	Variable chanNum // 1 or 2
	Variable output // 1 - primary, 2 - secondary
	
	switch( output )
		case 1:
			return NMMultiClampStrValue( chanNum, "ScaledOutSignal", NM_MultiClampUseLongNames )
		case 2:
			return NMMultiClampStrValue( chanNum, "RawOutSignal", NM_MultiClampUseLongNames )
	endswitch
	
	return ""
	
End // NMMultiClampSignal

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampValue( chanNum, varName )
	Variable chanNum // 1 or 2
	String varName // e.g. "Alpha"
	
	Variable scnt, value, serialNum, chanID, comPortID, axoBusID 
	String params, exStr
	
	String wname = NMMultiClampServerWave()
	
	switch( chanNum )
		case 1:
		case 2:
			break
		default:
			return Nan
	endswitch
	
	if ( WhichListItem( varName, NMMultiClampVarList( 0 ) ) < 0 )
		return Nan
	endif
	
	if ( NMMultiClampServersCheck() != 0 )
		return Nan
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return Nan
	endif
	
	Wave servers = $wname
	
	for ( scnt = 0 ; scnt < DimSize( servers, 0 ) ; scnt += 1 )
	
		serialNum = servers[ scnt ][ 0 ]
		chanID = servers[ scnt ][ 1 ]
		comPortID = servers[ scnt ][ 2 ]
		axoBusID = servers[ scnt ][ 3 ]
		
		if ( chanID == chanNum )
		
			Variable /G NM_TempValue = Nan
					
			if ( serialNum < 0 ) // 700A
				params = num2istr( comPortID ) + ", " + num2istr( axoBusID ) + ", " + num2istr( chanID ) + ", " + NMQuotes( varName ) 
				exStr = "NM_TempValue = AxonTelegraphAGetDataNum( " + params + " )"
			else // 700B
				params = num2istr( serialNum ) + ", " + num2istr( chanID ) + ", " + NMQuotes( varName )
				exStr = "NM_TempValue = AxonTelegraphGetDataNum( " + params + " )"
			endif
			
			try
				Execute /Q/Z exStr;AbortOnRTE
			catch
				//Print GetRTErrMessage()
			endtry
			
			value = NM_TempValue
			
			KillVariables /Z NM_TempValue
			
			return value
		
		endif
		
	endfor
	
	return Nan
	
End // NMMultiClampValue

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampStrValue( chanNum, varName, strLengthFlag )
	Variable chanNum // 1 or 2
	String varName // e.g. "ScaleFactorUnits"
	Variable strLengthFlag // ( 0 ) short name ( 1 ) long name
	
	Variable scnt, serialNum, chanID, comPortID, axoBusID
	String params, strValue, exStr
	
	String wname = NMMultiClampServerWave()
	
	switch( chanNum )
		case 1:
		case 2:
			break
		default:
			return ""
	endswitch
	
	if ( WhichListItem( varName, NMMultiClampStrVarList( 0 ) ) < 0 )
		return ""
	endif
	
	if ( NMMultiClampServersCheck() != 0 )
		return ""
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return ""
	endif
	
	Wave servers = $wname
	
	for ( scnt = 0 ; scnt < DimSize( servers, 0 ) ; scnt += 1 )
	
		serialNum = servers[ scnt ][ 0 ]
		chanID = servers[ scnt ][ 1 ]
		comPortID = servers[ scnt ][ 2 ]
		axoBusID = servers[ scnt ][ 3 ]
		
		if ( chanID == chanNum )
		
			String /G NM_TempStr = ""
		
			if ( serialNum < 0 ) // 700A
				params = num2istr( comPortID ) + ", " + num2istr( axoBusID ) + ", " + num2istr( chanID ) + ", " + NMQuotes( varName ) + ", " + num2istr( strLengthFlag )
				exStr = "NM_TempStr = AxonTelegraphAGetDataString( " + params + " )"
			else // 700B
				params = num2istr( serialNum ) + ", " + num2istr( chanID ) + ", " + NMQuotes( varName ) + ", " + num2istr( strLengthFlag )
				exStr = "NM_TempStr = AxonTelegraphGetDataString( " + params + " )"
			endif
			
			try
				Execute /Q/Z exStr;AbortOnRTE
			catch
				//print GetRTErrMessage()
			endtry
			
			strValue = NM_TempStr
			
			KillStrings /Z NM_TempStr
			
			return strValue
		
		endif
		
	endfor
	
	return ""
	
End // NMMultiClampStrValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphSave( folder )
	String folder // where to save MultiClamp Commander information ( "" ) for current data folder

	Variable scnt, numServers, icnt, value
	Variable serialNum, chanID, comPortID, axoBusID
	String subfolder1, subfolder2, params, varName, exStr
	
	String cdf = NMClampDF
	
	//if ( NumVarOrDefault( cdf+"DemoMode", 0 ) )
	//	return 0
	//endif
	
	if ( exists( "AxonTelegraphFindServers" ) != 4 ) // no XOP
		return 0
	endif
	
	if ( NumVarOrDefault( cdf+"MultiClamp700Save", 0 ) == 0 )
		return 0
	endif
	
	Variable /G NM_TempValue
	String /G NM_TempStr
	
	String varList = NMMultiClampVarList( 0 )
	String strVarList = NMMultiClampStrVarList( 0 )
	
	String wname = NMMultiClampServerWave()
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	if ( DataFolderExists( folder ) == 0 )
		return -1
	endif
	
	if ( NMMultiClampServersCheck() != 0 )
		return -1
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return -1
	endif

	Wave servers = $wname
	
	numServers = DimSize( servers, 0 )
	
	if ( numServers <= 0 )
		return -1
	endif
	
	subfolder1 = folder + "MultiClampTelegraphs:"
	
	if ( DataFolderExists( subfolder1 ) == 1 )
		KillDataFolder /Z $RemoveEnding( subfolder1, ":" )
	endif
	
	NewDataFolder /O $RemoveEnding( subfolder1, ":" )
	
	for ( scnt = 0 ; scnt < numServers ; scnt += 1 )
	
		serialNum = servers[ scnt ][ 0 ]
		chanID = servers[ scnt ][ 1 ]
		comPortID = servers[ scnt ][ 2 ]
		axoBusID = servers[ scnt ][ 3 ]
	
		if ( serialNum < 0 ) // 700A
			folder = "port" + num2istr( comPortID ) + "_bus" + num2istr( axoBusID ) + "_chan" + num2istr( chanID ) + ":"
			params = num2istr( comPortID ) + ", " + num2istr( axoBusID ) + ", " + num2istr( chanID ) + ", "
		else // 700B
			folder = "serial" + num2istr( serialNum ) + "_chan" + num2istr( chanID ) + ":"
			params = num2istr( serialNum ) + ", " + num2istr( chanID ) + ", "
		endif
		
		subfolder2 = subfolder1 + folder
		
		NewDataFolder /O $RemoveEnding( subfolder2, ":" )
		
		for ( icnt = 0 ; icnt < ItemsInList( varList ) ; icnt += 1 )
			
			varName = StringFromList( icnt, varList )
			
			if ( serialNum < 0 ) // 700A
				exStr = "NM_TempValue = AxonTelegraphAGetDataNum( " + params + NMQuotes( varName ) + " )"
			else // 700B
				exStr = "NM_TempValue = AxonTelegraphGetDataNum( " + params + NMQuotes( varName ) + " )"
			endif
			
			try
				Execute /Q/Z exStr;AbortOnRTE
			catch
				//print GetRTErrMessage()
			endtry
			
			Variable /G $subfolder2+varName = NM_TempValue
			
		endfor
		
		for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 )
			
			varName = StringFromList( icnt, strVarList )
			
			if ( serialNum < 0 ) // 700A
				exStr = "NM_TempStr = AxonTelegraphAGetDataString( " + params + NMQuotes( varName ) + ", " + num2istr( NM_MultiClampUseLongNames ) + " )"
			else // 700B
				exStr = "NM_TempStr = AxonTelegraphGetDataString( " + params + NMQuotes( varName ) + ", " + num2istr( NM_MultiClampUseLongNames ) + " )"
			endif
			
			try
				Execute /Q/Z exStr;AbortOnRTE
			catch
				//print GetRTErrMessage()
			endtry
			
			String /G $subfolder2+varName+"Str" = NM_TempStr
			
		endfor
	
	endfor
	
	KillVariables /Z NM_TempValue
	KillStrings /Z NM_TempStr
	
	return 0

End // NMMultiClampTelegraphSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampADCWavePath( stimDF, waveSelect )
	String stimDF
	String waveSelect
	
	String bdf = NMStimBoardDF( stimDF )
	
	strswitch( waveSelect )
	
		case "scale":
			return bdf + "ADCscale_MultiClamp"
			
		case "units":
			return bdf + "ADCunits_MultiClamp"
			
		case "name":
			return bdf + "ADCname_MultiClamp"
			
	endswitch
	
	return ""

End // NMMultiClampADCWavePath

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphsConfig( stimDF ) // configure scale factor waves
	String stimDF

	Variable icnt, found, numConfigs, chanNum, output, value, scale
	String modeStr, unitsStr
	String cdf = NMClampDF
	
	//if ( NumVarOrDefault( cdf+"DemoMode", 0 ) )
	//	return 0
	//endif
	
	String bdf = NMStimBoardDF( stimDF )
	
	String scaleName = NMMultiClampADCWavePath( stimDF, "scale" )
	String unitsName = NMMultiClampADCWavePath( stimDF, "units" )
	String signalName = NMMultiClampADCWavePath( stimDF, "name" )
	
	Wave /T ADCmode = $bdf+"ADCmode"
	
	numConfigs = numpnts( ADCmode )
	
	for ( icnt = 0 ; icnt < numConfigs ; icnt += 1 )
		
		if ( strsearch( ADCmode[ icnt ], "MultiClamp700", 0, 2 ) > 0 )
			found = 1
		endif
	
	endfor
	
	if ( found == 0 )
	
		KillWaves /Z $scaleName, $unitsName, $signalName
	
		SetNMvar( stimDF+"MultiClamp700", 0 ) // set MultiClamp flag to NO
		
		return 0
		
	endif
	
	if ( NMMultiClampTelegraphCheck() != 0 )
		return -1
	endif
	
	Make /O/N=( numConfigs ) $scaleName = Nan
	Make /T/O/N=( numConfigs ) $unitsName = ""
	Make /T/O/N=( numConfigs ) $signalName = ""
	
	Wave ADCscale = $scaleName
	Wave /T ADCunits = $unitsName
	Wave /T ADCname = $signalName
	
	for ( icnt = 0 ; icnt < numConfigs ; icnt += 1 )
	
		modeStr = ADCmode[ icnt ]
		
		if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
		
			chanNum = ClampTGainStrSearch( modeStr, "=C" )
			output = ClampTGainStrSearch( modeStr, "_O" )
			
			scale = NMMultiClampADCScale( chanNum, output )
			
			if ( numtype( scale ) > 0 )
				DoAlert 0, "Alert: located MultiClamp700 telegraph configurations but cannot access the Axon Telegraph Servers."
				NMMultiClampTelegraphCheck()
				return -1
			endif
			
			unitsStr = NMMultiClampUnits( chanNum, output )
			unitsStr = ReplaceString( "V/", unitsStr, "" )
			
			if ( StringMatch( unitsStr, "V" ) )
				scale /= 1000 // convert to mV
				unitsStr = "mV"
			endif
			
			ADCscale[ icnt ] = scale
			ADCunits[ icnt ] = unitsStr
			ADCname[ icnt ] = NMMultiClampSignal( chanNum, output )
			
		endif
		
	endfor
	
	SetNMvar( stimDF+"MultiClamp700", 1 ) // set MultiClamp flag to YES
	SetNMvar( cdf+"MultiClamp700Save", 1 ) // set MultiClamp flag to YES
	
	return 0

End // NMMultiClampTelegraphsConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampADCNum( stimDF, config, select )
	String stimDF
	Variable config
	String select // "scale"
	
	String wname = NMMultiClampADCWavePath( stimDF, select )
	
	if ( NumVarOrDefault( stimDF + "MultiClamp700", 0 ) == 0 )
		return Nan
	endif
	
	if ( WaveExists($wname) == 0 )
		return Nan
	endif
	
	if ( ( numtype( config ) > 0 ) || ( config < 0 ) || ( config >= numpnts( $wname ) ) )
		return Nan
	endif
	
	Wave ADC_MC = $wname
	
	return ADC_MC[ config ]
	
End // NMMultiClampADCNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMultiClampADCStr( stimDF, config, select )
	String stimDF
	Variable config
	String select // "name" or "units"
	
	String wname = NMMultiClampADCWavePath( stimDF, select )
	
	if ( NumVarOrDefault( stimDF + "MultiClamp700", 0 ) == 0 )
		return ""
	endif
	
	if ( WaveExists( $wname ) == 0 )
		return ""
	endif
	
	if ( ( numtype( config ) > 0 ) || ( config < 0 ) || ( config >= numpnts( $wname ) ) )
		return ""
	endif
	
	Wave /T ADC_MC = $wname
	
	return ADC_MC[ config ]
	
End // NMMultiClampADCStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampWaveNotes( wName, modeStr )
	String wName
	String modeStr
	
	Variable icnt, chanNum, output
	String varList, strVarList, varName
	
	if ( NMMultiClampTelegraphMode( modeStr ) == 0 )
		return -1
	endif
	
	chanNum = ClampTGainStrSearch( modeStr, "=C" )
	output = ClampTGainStrSearch( modeStr, "_O" )
	
	varList = NMMultiClampVarList( output )
	strVarList = NMMultiClampStrVarList( output )
	
	varList = RemoveFromList( strVarList, varList ) // remove redundant variables
	
	for ( icnt = 0 ; icnt < ItemsInList( varList ) ; icnt += 1 )
		varName = StringFromList( icnt, varList )
		Note $wName, "MultiClamp " + varName + ":" + num2str( NMMultiClampValue( chanNum, varName ) )
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 )
		varName = StringFromList( icnt, strVarList )
		Note $wName, "MultiClamp " + varName + ":" + NMMultiClampStrValue( chanNum, varName, NM_MultiClampUseLongNames )
	endfor
	
	return 0

End // NMMultiClampWaveNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTModeCheck( modeList )
	String modeList // list with two entries for channel 1 and 2
	
	Variable error
	String mode1, mode2, tmode1, tmode2
	
	if ( ItemsInList( modeList ) != 2 )
		DoAlert 0, "TmodeCheck Alert: MultiClamp700 configuration requires a telegraph mode entry for each channel."
		return -1
	endif
	
	if ( NMMultiClampTelegraphCheck() != 0 )
		return -1
	endif
	
	mode1 = StringFromList( 0, modeList )
	mode2 = StringFromList( 1, modeList )
	
	tmode1 = NMMultiClampStrValue( 1, "OperatingMode", 1 )
	tmode2 = NMMultiClampStrValue( 2, "OperatingMode", 1 )
	
	if ( ( StringMatch( mode1, "Dont Care" ) == 0 ) && ( StringMatch( mode1, tmode1 ) == 0 ) )
		ClampError(1, "channel 1 acquisition mode should be " + mode1)
		error = -1
	endif
	
	if ( ( StringMatch( mode2, "Dont Care" ) == 0 ) && ( StringMatch( mode2, tmode2 ) == 0 ) )
		ClampError(1, "channel 2 acquisition mode should be " + mode2)
		error = -1
	endif
	
	return error
	
End // NMMultiClampTModeCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphCheck()

	if ( exists( "AxonTelegraphFindServers" ) != 4 ) // no XOP
		DoAlert 0, "Alert: located MultiClamp700 telegraph configurations but cannot access the Axon Telegraph XOP."
		NMMultiClampTelegraphHowTo()
		return -1 // ERROR
	endif
	
	if ( NMMultiClampServersCheck() != 0 )
		DoAlert 0, "Alert: located MultiClamp700 telegraph configurations but cannot access the MultiClamp Command Servers."
		return -1 // ERROR
	endif
	
	return 0
	
End // NMMultiClampTelegraphCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphSaveCheck()

	String cdf = NMClampDF

	if ( ( NumVarOrDefault( cdf+"MultiClamp700Save", 0 ) == 1 ) && ( exists( "AxonTelegraphFindServers" ) != 4 ) )
		DoAlert 0, "Alert: MultiClamp700Save is on but NM cannot access the Axon Telegraph XOP."
		return 0
	endif
	
	if ( ( exists( "AxonTelegraphFindServers" ) == 4 ) && ( NumVarOrDefault( cdf+"MultiClamp700Save", 0 ) == 0 ) )
	
		DoAlert 1, "Located Axon Telegraph XOP. Do you want to save MultiClamp 700 Commander variables inside your acquired NM data folders?"

		if ( V_flag == 1 )
			NMConfigVarSet( "Clamp", "MultiClamp700Save", 1 )
			DoAlert 0, "Alert: MultiClamp 700 Commander should be open during acquisition."
		endif
		
	endif

End // NMMultiClampTelegraphSaveCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMultiClampTelegraphHowTo()
	
	String txt = "The Telegraph Gain configuration for Multiclamp amplifiers requires the AxonTelegraph XOP. " + NMCR
	
	txt += "To learn how to install, enter the following text into the Igor Command Line: " + NMCR
	txt += "DisplayHelpTopic " + NMQuotes( "Installing The AxonTelegraph XOP" )

	NMDoAlert( ReplaceString( NMCR, txt, "" ), title = "Install AxonTelegraph XOP" )
	NMHistory( txt )

End // NMMultiClampTelegraphHowTo

//****************************************************************
//****************************************************************
//****************************************************************