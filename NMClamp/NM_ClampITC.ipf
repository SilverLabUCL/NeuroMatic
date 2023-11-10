#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2024 The Silver Lab, UCL
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
//
//	Clamp ITC Acquisition Functions ( ITC16 / ITC18 )
//
//	Error Alerts:
//	1. expected ';' or <cr> regarding ITC18Seq "0","0",1
//
//	if you get an error regarding the "Seq" command, try changing
//	the ITC18_SeqExtraParameter below to zero.
//
//	Additional code by Gregory Jefferis ( GJ ), MRC Laboratory of Molecular Biology
//
//****************************************************************
//****************************************************************

Static Constant ITC_SetADCRange = 0 // ( 0 ) no ( 1 ) yes, allows one to change the ADC gain
Static Constant ITC_ResetOn = 0 // ( 0 ) no ( 1 ) yes, use this to turn on ITC Reset commands

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCconfig( aboard )
	String aboard
	
	Variable ITC18_SeqExtraParameter
	
	String cdf = NMClampDF
	
	Execute /Z aboard + "Reset" // attemp to reset ITC board
	
	if ( V_flag != 0 )
		return -1
	endif
	
	Make /I/O/N=1 $( cdf+"Avail2Write" )

	Execute aboard + "WriteAvailable " + cdf + "Avail2Write"

	Wave Avail2Write = $cdf+"Avail2Write"
	
	SetNMvar( cdf+"ITC_FIFO_size", Avail2Write[ 0 ] ) // save FIFO size ( GJ )
	
	SetNMvar( cdf+"BoardDriver", 0 )
	SetNMstr( cdf+"BoardList", aboard + ";" )
	
	if ( StringMatch( aboard, "ITC16" ) == 1 )
		return 0 // everything OK
	endif
	
	// determine number of parameters to pass for ITC18Seq command
	
	ITC18_SeqExtraParameter = NumVarOrDefault( cdf + "ITC18_SeqExtraParameter", 1 )
	
	if ( ITC18_SeqExtraParameter == 1 )
	
		Execute /Z aboard + "Seq " + NMQuotes( "0" ) + "," + NMQuotes( "0" ) + ",1"
		
		if ( V_Flag != 0 )
		
			Execute /Z aboard + "Seq " + NMQuotes( "0" ) + "," + NMQuotes( "0" )
			
			if ( V_Flag == 0 )
				SetNMvar( cdf + "ITC18_SeqExtraParameter" , 0 )
			else
				return ClampError( 1, "ITCconfig : " + aboard + "Seq command error" )
			endif
		
		endif
		
	else
	
		Execute /Z aboard + "Seq " + NMQuotes( "0" ) + "," + NMQuotes( "0" )
		
		if ( V_Flag != 0 )
		
			Execute /Z aboard + "Seq " + NMQuotes( "0" ) + "," + NMQuotes( "0" ) + ",1"
			
			if ( V_Flag == 0 )
				SetNMvar( cdf + "ITC18_SeqExtraParameter" , 1 )
			else
				return ClampError( 1, "ITCconfig : " + aboard + "Seq command error" )
			endif
			
		endif
		
	endif
	
	return 0
	
End // ITCconfig

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCacquire( mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) test timers
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime
	
	Variable pnts
	
	String cdf = NMClampDF, sdf = StimDF()
	
	String aboard = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	Variable acqMode = NumVarOrDefault( sdf+"AcqMode", 0 )
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 0 )
	
	Variable ITC_FIFO_size = NumVarOrDefault( cdf+"ITC_FIFO_size", 256000 )
	
	if ( ITCupdateLists( NumStimWaves ) == -1 )
		return -1 // bad input/output configuration
	endif
	
	String seqstr = ITCseqStr() // sequence strings created by ITCupdateLists
	
	Variable outs = strlen( StringFromList( 0, seqstr ) )
	Variable ins = strlen( StringFromList( 1, seqstr ) )
	
	if ( outs != ins ) // double check
		return ClampAcquireError( "ITCacquire Error", "number of inputs does not equal number of outputs." )
	endif
	
	pnts = ceil( ( WaveLength + InterStimTime ) * ins / SampleInterval )
	
	if ( acqMode == 0 ) // epic precise
	
		if ( pnts > ITC_FIFO_size / 2 ) // must be able to load at least two for epic precise
			return ClampAcquireError( "ITCacquire Error", "epic precise mode not feasible. Please use episodic mode instead." )
		endif
		
	endif
	
	SetNMvar( cdf+"AcqMode", acqMode ) // set temporary variable in NMClampDF
	
	SetNMvar( cdf+"InterStimTime", InterStimTime )
	SetNMvar( cdf+"InterRepTime", InterRepTime )
	
	switch( acqMode )
		case 0: // epic precise
		case 1: // continuous
		case 4: // continuous triggered
			ITCAcqPrecise( mode, savewhen )
			break
		case 2: // episodic
		case 3: // episodic triggered
			ITCAcqLong( mode, savewhen )
			break
		default:
			return ClampAcquireError( "ITCacquire Error", "acquisition mode not recognized: " + num2istr( acqMode ) )
	endswitch 
	
End // ITCacquire

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCAcqPrecise( mode, savewhen )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) test timers
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while

	Variable nwaves, rcnt, ccnt, wcnt, icnt, period, pipe
	Variable stimcnt, stimtotal, sampcnt, samptotal, savecnt
	Variable outpnts, inpnts, savepnts, npnts, config, scale, tscale = 1
	Variable gain, tgainavg, tgainv, tgainChan, cancel, outs, ins
	Variable flip, flipread, flipsave, acqflag = 2
	Variable firstread = 1, firstwrite = 1
	
	String wname, dname, inName, outName, saveName, alist, dlist, tlist
	String item, chanstr, seqstr, ITCoutList, ITCinList, instr, modeStr
	
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	String aboard = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	Variable NumStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 0 )
	Variable NumStimReps = NumVarOrDefault( sdf+"NumStimReps", 0 )
	
	NVAR InterStimTime = $cdf+"InterStimTime"
	NVAR InterRepTime = $cdf+"InterRepTime"
	
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 0 )
	Variable acqMode = NumVarOrDefault( cdf+"AcqMode", 0 )
	
	Variable continuous = ( acqMode == 1 ) || ( acqMode == 4 )
	
	strswitch( aboard )
		case "ITC16":
		case "ITC18":
			break
		default:
			return ClampAcquireError( "ITCAcqPrecise Error", "unrecognized board : " + aboard )
	endswitch
	
	nwaves = NumStimWaves * NumStimReps // total number of waves
	
	Make /I/O/N=1 $( cdf+"Avail2Read" ), $( cdf+"Avail2Write" )
	
	Wave Avail2Read = $cdf+"Avail2Read"
	Wave Avail2Write = $cdf+"Avail2Write"
	
	Wave ADCscale = $bdf+"ADCscale"
	Wave ADCchan = $bdf+"ADCchan"
	Wave /T ADCmode = $bdf+"ADCmode"
	
	Wave stimPnts = $cdf+"StimNumpnts"
	
	Wave /T ADClist = $cdf+"ADClist"
	Wave /T DAClist = $cdf+"DAClist"
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T preADClist = $cdf+"preADClist"
	
	Variable tGainConfig = NumVarOrDefault( cdf+"TGainConfig", 0 )
	//String instr = StrVarOrDefault( cdf+"ClampInstrument", "" )
	
	Variable ITC18_SeqExtraParameter = NumVarOrDefault( cdf+"ITC18_SeqExtraParameter", 1 )
	Variable ITC_FIFO_size = NumVarOrDefault( cdf+"ITC_FIFO_size", 256000 )
	
	seqstr = ITCseqStr()
	
	ITCoutList = StringFromList( 0, seqstr )
	ITCinList = StringFromList( 1, seqstr )
	
	outs = strlen( ITCoutList )
	ins = strlen( ITCinList )
	
	pipe = ITCpipeDelay( ins )
	
	if ( outs != ins ) // double check
		return ClampAcquireError( "ITCAcqPrecise error", "number of outputs does not equal number of inputs." )
	endif
	
	period = ITCperiod( SampleInterval, outs )

	if ( period == -1 )
		return -1 // bad sample interval
	endif
	
	if ( ClampAcquireStart( mode, nwaves ) == -1 )
		return -1
	endif
	
	if ( ITCupdateLists( NumStimWaves ) == -1 ) // recreate lists in case they changed during ClampAcquireStart
		return -1
	endif
	
	if ( ITCmakeWaves( outs, NumStimWaves, InterStimTime, NumStimReps, InterRepTime, acqMode ) == -1 )
		return -1
	endif
	
	if ( ITCprescan() == -1 )
		return -1
	endif
	
	if ( acqMode == 4 )
		acqflag = 3 // external trigger
	endif
	
	// set up telegraph gains
	
	if ( tGainConfig )
		ClampTGainScaleValue( bdf )
	endif
	
	// now do normal acquisition
	
	outName = sdf + "ITCoutWave0"
	inName = sdf + "ITCinWave0"
	saveName = sdf + "ITCinWave0"
	
	if ( 0 < numpnts( ADClist ) )
		alist = ADClist[ 0 ]
	else
		alist = ""
	endif
	
	outpnts = numpnts( $outName )
	inpnts = numpnts( $inName )
	savepnts = numpnts( $saveName )
	
	if ( outpnts > ITC_FIFO_size )
		return ClampAcquireError( "ITCAcqPrecise error", "not enough FIFO space." )
	endif
	
	Wave savetemp = $saveName
	
	savetemp = Nan
	
	if ( ( NumStimWaves == 1 ) && ( NumStimReps > 1 ) )
		// must have more than one input wave
		// so create a copy and flip back and forth
		Duplicate /O savetemp $( sdf+"ITCinWave" )
		flip = 1 
	endif
	
	if ( ITC_ResetOn == 1 )
		Execute aboard + "Reset"
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( alist ) ; icnt += 1 )
	
		item = StringFromList( icnt, alist )
		chanstr = StringFromList( 1,item,"," )
		gain = str2num( StringFromList( 2,item,"," ) )
		
		if ( ITC_SetADCRange == 1 )
			Execute aboard + "SetADCRange " + chanstr + "," + ITCrangeStr( gain )
		endif
		
	endfor
	
	strswitch( aboard )
		case "ITC16":
			Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\""
			break
		case "ITC18":
			if ( ITC18_SeqExtraParameter == 1 )
				Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\",1"
			else
				Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\""
			endif
			break
	endswitch
	
	do // preload output waves
		
		if ( firstwrite == 1 ) // GJ
			Avail2Write[ 0 ] = ITC_FIFO_size
		else
			Execute aboard + "WriteAvailable " + cdf + "Avail2Write"
		endif // GJ
		
		if ( ( stimtotal < nwaves ) && ( outpnts <= Avail2Write[ 0 ] ) )
			
			if ( firstwrite == 1 )
				Execute aboard + "Stim " + outName
				firstwrite = 0
			else
				Execute aboard + "StimAppend " + outName
			endif
			
			stimcnt += 1
			stimtotal += 1
			
			if ( stimcnt >= NumStimWaves )
				stimcnt = 0
			endif
			
			outName = sdf + "ITCoutWave" + num2istr( stimcnt )
			
			outpnts = numpnts( $outName )
			
		else
		
			break
			
		endif
		
	while ( 1 )
	
	strswitch( aboard )
		case "ITC16":
			Execute aboard + "StartAcq " + num2str( period ) + ", " + num2str( acqflag )
			break
		case "ITC18":
			Execute aboard + "StartAcq " + num2str( period ) + ", " + num2str( acqflag ) + ", 0"
			break
	endswitch
	
	do
		
		Execute aboard + "WriteAvailable " + cdf + "Avail2Write"
		
		if ( ( stimtotal < nwaves ) && ( outpnts <= Avail2Write[ 0 ] ) )
			
			Execute aboard + "StimAppend " + outName
			
			stimcnt += 1
			stimtotal += 1
			
			if ( stimcnt >= NumStimWaves )
				stimcnt = 0
			endif
			
			outName = sdf + "ITCoutWave" + num2istr( stimcnt )
			outpnts = numpnts( $outName )
			
		endif
		
		Execute aboard + "ReadAvailable " + cdf + "Avail2Read"
		
		if ( ( samptotal < nwaves ) && ( inpnts <= Avail2Read[ 0 ] ) )

			if ( firstread == 1 )
				Execute aboard + "Samp " + inName
				firstread = 0
			else
				Execute aboard + "SampAppend " + inName
			endif
				
			sampcnt += 1
			samptotal += 1
			
			if ( sampcnt >= NumStimWaves )
				sampcnt = 0
			endif
			
			if ( ( flip == 0 ) || ( flipread == 1 ) )
				inName = sdf + "ITCinWave"+ num2istr( sampcnt )
				flipread = 0
			else
				inName = sdf + "ITCinWave" 
				flipread = 1
			endif
			
			inpnts = numpnts( $inName )

			Wave wtemp = $inName
			
			if ( samptotal < nwaves )
				wtemp = Nan
			endif
			
		endif
		
		if ( numtype( savetemp[ savepnts - 1 ] ) == 0 )
		
			if ( ( continuous == 1 ) && ( mode == 0 ) )
				savetemp[0,pipe-1] = Nan // delete pipedelay points if in continuous preview
			endif
	
			ITCmixWaves( saveName, ins, alist, "", stimPnts[savecnt], 0, -1, pipe ) // unmix waves, shift
			
			for ( ccnt = 0 ; ccnt < ItemsInList( alist ) ; ccnt += 1 ) // save waves
				
				item = StringFromList( ccnt,alist )
				dname = StringFromList( 0,item,"," )
				//chan = str2num( StringFromList( 1,item,"," ) )
				config = str2num( StringFromList( 3,item,"," ) )
				
				modeStr = ADCmode[ config ]
		
				if ( mode == 1 )
					wname = GetWaveName( "default", ccnt, CurrentNMWave() )
				else
					wname = GetWaveName( "default", ccnt, 0 )
				endif
				
				if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
					scale = NMMultiClampADCNum( sdf, config, "scale" )
				else
					scale = ADCscale[config]
				endif
				
				//f ( ( tGainConfig == 1 ) && ( tgainv > 0 ) && ( numtype( ADCtgain[config] ) == 0 ) )
					//scale = tscale
				//endif
				
				if ( ( numtype( scale ) > 0 ) || ( scale <= 0 ) )
					scale = 1
				endif

				Wave wtemp = $dname
				
				if ( ( numtype( scale ) == 0 ) && ( scale > 0 ) )
					wtemp /= scale
				else
					scale = 1
				endif

				Duplicate /O wtemp $wname
				
				Note $wname, "Scale Factor:" + num2str( scale )
				
				if ( acqMode == 0 )
					ChanWaveMake( ccnt, wName, dName, xWave = "" ) // update display wave ( smooth, dt, etc )
				endif
				
				if ( NumVarOrDefault( ChanDF( ccnt )+"overlay", 0 ) > 0 )
					ChanOverlayUpdate( ccnt )
				endif
				
				if ( ( mode == 1 ) && ( saveWhen == 2 ) )
					ClampNMBAppend( wname ) // update waves in saved folder
				endif
			
			endfor
			
			cancel = ClampAcquireNext( mode, nwaves )
			
			savecnt += 1
			
			if ( savecnt >= NumStimWaves )
				savecnt = 0
				rcnt += 1
			endif
			
			if ( rcnt >= NumStimReps )
				break
			endif
			
			if ( ( flip == 0 ) || ( flipsave == 1 ) )
				saveName = sdf + "ITCinWave" + num2istr( savecnt )
				flipsave = 0
			else
				saveName = sdf + "ITCinWave"
				flipsave = 1
			endif
			
			alist = ADClist[savecnt]
			savepnts = numpnts( $saveName )
	
			Wave savetemp = $saveName
			
			if ( cancel == 1 )
				break
			endif
			
		endif
		
	while ( 1 )
	
	Execute aboard + "stopacq"
	
	//Execute /Z aboard + "Reset" // reset board
	
	if ( ( continuous == 1 ) && ( mode == 1 ) ) // fix pipeline delay
		
		pipe = pipe/ins
		
		for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
		
			alist = ADClist[wcnt]
			
			for ( ccnt = 0 ; ccnt < ItemsInList( alist ) ; ccnt += 1 ) // save waves
			
				wname = GetWaveName( "default", ccnt, wcnt ) // current wave
				dname = GetWaveName( "default", ccnt, wcnt+1 ) // next wave
		
				if ( WaveExists( $wname ) )
					Wave wtemp = $wname
					npnts = numpnts( wtemp )
					wtemp[npnts-pipe, npnts-1] = Nan
				else
					continue
				endif
				
				if ( WaveExists( $dname ) && ( numpnts( $wName ) == numpnts( $dname ) ) )
					Wave dtemp = $dname
					for ( icnt = 0 ; icnt < pipe ; icnt += 1 )
						wtemp[npnts-pipe+icnt] = dtemp[npnts-pipe+icnt]
					endfor
				endif
			
			endfor
		endfor
		
	endif
	
	for ( wcnt = 0 ; wcnt < NumStimWaves ; wcnt += 1 )
		KillWaves /Z $sdf+"ITCoutWave"+num2istr( wcnt )
		KillWaves /Z $sdf+"ITCinWave"+num2istr( wcnt )
	endfor
	
	KillWaves /Z $( sdf+"ITCinWave" ), $( sdf+"ITCmix" ), $( sdf+"ITCTTLOUT" )
	
	ClampAcquireFinish( mode, savewhen, 1 )
	
	if ( continuous == 1 )
		NMMainXScaleMode( mode = "Continuous" )
	endif

End // ITCAcqPrecise

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCAcqLong( mode, savewhen )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) test timers
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while
	
	Variable nwaves, rcnt, ccnt, wcnt, icnt, period, pipe
	Variable stimcnt, stimtotal, sampcnt, samptotal
	Variable config, scale = 1, tscale = 1
	Variable gain, tgainv, tgainChan, cancel, outs, ins
	Variable flip, flipread, flipsave
	Variable firstread, firstwrite, firstsave, acqflag = 2
	
	String wname, dname, inName, outName, alist, instr, modeStr
	String item, chanstr, seqstr, ITCoutList, ITCinList
	
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	String aboard = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	Variable NumStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 0 )
	Variable NumStimReps = NumVarOrDefault( sdf+"NumStimReps", 0 )
	
	NVAR InterStimTime = $cdf+"InterStimTime"
	NVAR InterRepTime = $cdf+"InterRepTime"
	
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 0 )
	Variable acqMode = NumVarOrDefault( cdf+"AcqMode", 0 )
	
	strswitch( aboard )
		case "ITC16":
		case "ITC18":
			break
		default:
			return ClampAcquireError( "ITCAcqLong Error", "unrecognized board : " + aboard )
	endswitch
	
	nwaves = NumStimWaves * NumStimReps // total number of waves
	
	Make /I/O/N=1 $( cdf+"Avail2Read" ), $( cdf+"Avail2Write" )
	
	Wave Avail2Read = $cdf+"Avail2Read"
	Wave Avail2Write = $cdf+"Avail2Write"
	
	Wave stimPnts = $cdf+"StimNumpnts"
	
	Wave ADCscale = $bdf+"ADCscale"
	Wave ADCchan = $bdf+"ADCchan"
	Wave /T ADCmode = $bdf+"ADCmode"
	
	Wave /T ADClist = $cdf+"ADClist"
	
	Variable tGainConfig = NumVarOrDefault( cdf+"TGainConfig", 0 )
	
	Variable ITC18_SeqExtraParameter = NumVarOrDefault( cdf+"ITC18_SeqExtraParameter", 1 )
	Variable ITC_FIFO_size = NumVarOrDefault( cdf+"ITC_FIFO_size", 256000 )
	
	seqstr = ITCseqStr()
	ITCoutList = StringFromList( 0, seqstr )
	ITCinList = StringFromList( 1, seqstr )
	
	outs = strlen( ITCoutList )
	ins = strlen( ITCinList )
	
	pipe = ITCpipeDelay( ins )
	
	if ( outs != ins ) // double check
		return ClampAcquireError( "ITCAcqLong Error", "configuration error." )
	endif
	
	period = ITCperiod( SampleInterval, outs )

	if ( period == -1 )
		return -1 // bad sample interval
	endif
	
	if ( ClampAcquireStart( mode, nwaves ) == -1 )
		return -1
	endif
	
	if ( ITCupdateLists( NumStimWaves ) == -1 ) // recreate lists in case they changed during ClampAcquireStart
		return -1
	endif
	
	if ( ITCmakeWaves( outs, NumStimWaves, InterStimTime, NumStimReps, InterRepTime, acqMode ) == -1 )
		return -1
	endif
	
	if ( ITCprescan() == -1 )
		return -1
	endif
	
	if ( acqMode == 3 )
		acqflag = 3 // external trigger
	endif
	
	if ( numpnts( ADClist ) == 0 )
		return -1
	endif
	
	// set up telegraph gains
	
	if ( tGainConfig )
		ClampTGainScaleValue( bdf )
	endif
	
	// start acquisition
	
	for ( rcnt = 0 ; rcnt < NumStimReps ; rcnt += 1 ) // loop thru reps

		for ( wcnt = 0 ; wcnt < NumStimWaves ; wcnt += 1 ) // loop thru stims
		
			// THIS BLOCK OF CODE MOVED INSIDE LOOP BY Jason Rothman, 2 Oct 2008 >>>
		
			if ( ITC_ResetOn == 1 )
				Execute aboard + "Reset"
			endif
	
			for ( icnt = 0 ; icnt < ItemsInList( ADClist[ 0 ] ) ; icnt += 1 )
			
				item = StringFromList( icnt, ADClist[ 0 ] )
				chanstr = StringFromList( 1,item,"," )
				gain = str2num( StringFromList( 2,item,"," ) )
				
				if ( ITC_SetADCRange == 1 )
					Execute aboard + "SetADCRange " + chanstr + "," + ITCrangeStr( gain )
				endif
				
			endfor
			
			strswitch( aboard )
				case "ITC16":
					Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\""
					break
				case "ITC18":
					if ( ITC18_SeqExtraParameter == 1 )
						Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\",1"
					else
						Execute aboard + "Seq \"" + ITCoutList + "\",\"" + ITCinList + "\""
					endif
					break
			endswitch
			
			// <<< THIS BLOCK OF CODE MOVED INSIDE LOOP BY Jason Rothman, 2 Oct 2008
			
			outName = sdf + "ITCoutWave" + num2istr( wcnt )
			inName = sdf + "ITCinWave"+ num2istr( wcnt )
			
			if ( wcnt >= numpnts( ADClist ) )
				return ClampAcquireError( "ITCAcqLong Error", "bad ADClist configuration." )
			endif
			
			alist = ADClist[ wcnt ]
			
			if ( numpnts( $outName ) > ITC_FIFO_size )
				return ClampAcquireError( "ITCAcqLong Error", "not enough FIFO space." )
			endif
			
			Wave wtemp = $inName
				
			wtemp = Nan
			
			firstwrite = 1
			firstread = 1
			firstsave = 1
			
			do
			
				// Execute aboard + "WriteAvailable " + cdf + "Avail2Write" // removed 12 May 2010
			
				if ( firstwrite == 1 )
					Execute aboard + "Stim " + outName
					firstwrite = 0
				endif
				
			while ( firstwrite == 1 )
			
			strswitch( aboard )
				case "ITC16":
					Execute aboard + "StartAcq " + num2str( period ) + ", " + num2str( acqflag )
					break
				case "ITC18":
					Execute aboard + "StartAcq " + num2str( period ) + ", " + num2str( acqflag ) + ", 0"
					break
			endswitch
			
			do
				
				Execute aboard + "ReadAvailable " + cdf + "Avail2Read"
				
				if ( ( firstread == 1 ) && ( firstwrite == 0 ) && ( numpnts( $inName ) + 10 < Avail2Read[ 0 ] ) )
					Execute aboard + "Samp " + inName
					firstread = 0
				endif
				
			while ( firstread == 1 )
			
			do
				
				if ( ( firstread == 0 ) && ( firstwrite == 0 ) && ( numtype( wtemp[numpnts( wtemp )-1] ) == 0 ) )
				
					Execute aboard + "stopacq"
					
					if ( wcnt >= numpnts( stimPnts ) )
						return ClampAcquireError( "ITCAcqLong Error", "wave count out of range for wave stimPnts" )
					endif
		
					ITCmixWaves( inName, ins, alist, "", stimPnts[wcnt], 0, -1, pipe ) // unmix waves, shift
					
					for ( ccnt = 0 ; ccnt < ItemsInList( alist ) ; ccnt += 1 ) // save waves
						
						item = StringFromList( ccnt,alist )
						dname = StringFromList( 0,item,"," )
						//chan = str2num( StringFromList( 1,item,"," ) )
						config = str2num( StringFromList( 3,item,"," ) )
						
						modeStr = ADCmode[ config ]
				
						if ( mode == 1 )
							wname = GetWaveName( "default", ccnt, CurrentNMWave() )
						else
							wname = GetWaveName( "default", ccnt, 0 )
						endif
						
						if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
							scale = NMMultiClampADCNum( sdf, config, "scale" )
						else
							scale = ADCscale[config]
						endif
						
						//if ( ( tGainConfig == 1 ) && ( tgainv > 0 ) && ( numtype( ADCtgain[config] ) == 0 ) )	
							//scale = tscale
						//endif
						
						if ( ( numtype( scale ) > 0 ) || ( scale <= 0 ) )
							scale = 1
						endif
		
						Wave wtemp = $dname
						
						if ( ( numtype( scale ) == 0 ) && ( scale > 0 ) )
							wtemp /= scale
						else
							scale = 1
						endif
		
						Duplicate /O wtemp $wname
						
						Note $wname, "Scale Factor:" + num2str( scale )
						
						ChanWaveMake( ccnt, wName, dName, xWave = "" ) // update display wave ( smooth, dt, etc )
						
						if ( NumVarOrDefault( ChanDF( ccnt )+"overlay", 0 ) > 0 )
							ChanOverlayUpdate( ccnt )
						endif
						
						if ( ( mode == 1 ) && ( saveWhen == 2 ) )
							ClampNMBAppend( wname ) // update waves in saved folder
						endif
					
					endfor
					
					cancel = ClampAcquireNext( mode, nwaves )
					
					firstsave = 0
					
				endif
			
			while ( firstsave == 1 )
			
			if ( NMProgressCancel() == 1 )
				break
			endif
			
			if ( ( rcnt == NumStimReps - 1 ) && ( wcnt == NumStimWaves - 1 ) )
				break // finished
			else
				ClampWaitMSTimer( InterStimTime ) // inter-wave time
			endif
			
			if ( NMProgressCancel() == 1 )
				break
			endif
			
		endfor
		
		if ( rcnt < NumStimReps - 1 )
			ClampWaitMSTimer( InterRepTime ) // inter-rep time
		endif
		
		if ( NMProgressCancel() == 1 )
			break
		endif
		
	endfor
	
	Execute aboard + "stopacq"
	
	//Execute /Z aboard + "Reset" // reset board
	
	for ( wcnt = 0 ; wcnt < NumStimWaves ; wcnt += 1 )
		KillWaves /Z $sdf+"ITCoutWave"+num2istr( wcnt )
		KillWaves /Z $sdf+"ITCinWave"+num2istr( wcnt )
	endfor
	
	KillWaves /Z $( sdf+"ITCinWave" ), $( sdf+"ITCmix" ), $( sdf+"ITCTTLOUT" )
	
	ClampAcquireFinish( mode, savewhen, 1 )

End // ITCAcqLong

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCprescan()

	Variable icnt, gain, config, npnts, period, scale, gscale
	String item, inName, chanstr
	
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	String aboard = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	Variable ITC18_SeqExtraParameter = NumVarOrDefault( cdf+"ITC18_SeqExtraParameter", 1 )
	
	Wave ADCscale = $bdf+"ADCscale"
	
	Wave /T preADClist = $cdf+"preADClist"
	
	if ( numpnts( preADClist ) == 0 )
		return 0
	endif
	
	period = ITCperiod( 0.01, 1 )
	
	if ( ITC_ResetOn == 1 )
		Execute aboard + "Reset"
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( preADClist[ 0 ] ) ; icnt += 1 )

		item = StringFromList( icnt, preADClist[ 0 ] )
		inName = StringFromList( 0,item,"," )
		chanstr = StringFromList( 1,item,"," )
		gain = str2num( StringFromList( 2,item,"," ) )
		config = str2num( StringFromList( 4,item,"," ) )
		
		if ( WaveExists( $inName ) == 0 )
			continue
		endif
		
		Wave tempWave = $inName
		
		npnts = numpnts( tempWave )
		
		Redimension /N=( 6+npnts ) tempWave
		
		tempWave = 0
		
		if ( ITC_SetADCRange == 1 )
			Execute aboard + "SetADCRange " + chanstr + "," + ITCrangeStr( gain )
		endif
	
		strswitch( aboard )
			case "ITC16":
				Execute aboard + "Seq \"0\",\"" + chanstr + "\""
				Execute aboard + "StartAcq " + num2str( period ) + ", 2"
				break
			case "ITC18":
				if ( ITC18_SeqExtraParameter == 1 )
					Execute aboard + "Seq \"0\",\"" + chanstr + "\",1"
				else
					Execute aboard + "Seq \"0\",\"" + chanstr + "\""
				endif
				Execute aboard + "StartAcq " + num2str( period ) + ", 2, 0"
				break
		endswitch
		
		Execute aboard + "Stim " + inName
		Execute aboard + "Samp " + inName
		Execute aboard + "stopacq"
		
		Rotate -6, tempWave
		
		Redimension /N=( npnts ) tempWave
		
		gscale = ITCrange( gain )
		
		if ( gscale > 0 )
			tempWave /= 32768 / gscale // convert to volts
		endif
		
		if ( ( numtype( config ) == 0 ) && ( config >= 0 ) && ( config < numpnts( ADCscale ) ) )
		
			scale = ADCscale[config]
			
			if ( ( numtype( scale ) == 0 ) && ( scale > 0 ) )
				tempWave /= scale
			endif
			
		endif
	
	endfor
	
	ClampTelegraphAuto()
	
End // ITCprescan

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCread( chan, gain, npnts )
	Variable chan // ADC channel to read
	Variable gain // input gain
	Variable npnts // number of points to read
	
	Variable gscale
	
	String chanstr = num2istr( chan )
	
	String cdf = NMClampDF
	
	String aboard = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	Variable ITC18_SeqExtraParameter = NumVarOrDefault( cdf+"ITC18_SeqExtraParameter", 1 )
	
	Variable period = ITCperiod( 0.01, 1 )
	
	Variable garbage = 15
	
	Make /O/N=( npnts+garbage ) CT_ITCread = Nan
	
	if ( ITC_ResetOn == 1 )
		Execute aboard + "Reset"
	endif
	
	if ( ITC_SetADCRange == 1 )
		Execute aboard + "SetADCRange " + chanstr + "," + ITCrangeStr( gain )
	endif
	
	strswitch( aboard )
		case "ITC16":
			Execute aboard + "Seq \"0\",\"" + chanstr + "\""
			Execute aboard + "StartAcq " + num2str( period ) + ", 2"
			break
		case "ITC18":
			if ( ITC18_SeqExtraParameter == 1 )
				Execute aboard + "Seq \"0\",\"" + chanstr + "\",1"
			else
				Execute aboard + "Seq \"0\",\"" + chanstr + "\""
			endif
			Execute aboard + "StartAcq " + num2str( period ) + ", 2, 0"
			break
	endswitch
	
	Execute aboard + "Stim CT_ITCread"
	Execute aboard + "Samp CT_ITCread"
	Execute aboard + "stopacq"
	
	Wave CT_ITCread
	
	gscale = ITCrange( gain )
	
	if ( gscale > 0 )
		CT_ITCread /= 32768 / gscale // convert to volts
	endif
	
	CT_ITCread[ 0, garbage-1 ] = Nan
	
	CT_ITCread = Zero2Nan( CT_ITCread ) // remove possible 0's
	
	WaveStats /Q CT_ITCread
	
	KillWaves /Z CT_ITCread
	
	SetNMvar( cdf+"ClampReadValue", V_avg )
	
	return V_avg // return average of points

End // ITCread

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCperiod( sampleinterval, outs ) // period in ITC18 clock intervals
	Variable sampleinterval, outs

	String cdf = NMClampDF

	Variable period = 1000 * sampleinterval / ( 1.25 * outs ) // number of ticks
	Variable remain = mod( period, floor( period ) )
	Variable three = mod( outs, 3 )
	
	if ( remain >= 0.01 )
	
		period = ceil( period )
		sampleinterval = 5 * floor( period / 5 ) * 1.25 * outs / 1000 // to nearest 5 usec
		
		if ( three == 0 )
			return ClampAcquireError( "ITCperiod Error", "bad sample interval. Try multiple of 0.03 msec." )
		else
			return ClampAcquireError( "ITCperiod Error", "bad sample interval. Try multiple of 0.01 msec." )
		endif
		
	endif
	
	if ( period <= 5 )
		return ClampAcquireError( "ITCperiod Error", "sample inteval too short" )
	endif
	
	if ( period >= 82000 )
		return ClampAcquireError( "ITCperiod Error", "sample inteval too long" )
	endif
	
	return floor( period )

End // ITCperiod

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCupdateLists( NumStimWaves ) // check input/output configurations and create sequence wave lists
	Variable NumStimWaves

	Variable wcnt, config, chan, gain, mode, outs, ins, tgain
	String wname, alist, dlist, tlist, alist2, item, modestr, nowave = ""
	
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	Variable npnts = NumVarOrDefault( sdf+"SamplesPerWave", Nan )
	
	Variable tpnts = NM_ClampTelegraphSamplesToRead
	
	if ( WaveExists( $bdf+"ADCname" ) == 0 )
		return -1
	endif
	
	Wave /T ADCname = $bdf+"ADCname"
	Wave /T DACname = $bdf+"DACname"
	Wave /T TTLname = $bdf+"TTLname"
	
	Wave ADCtgain = $bdf+"ADCtgain" // telegraph gain
	
	Make /O/N=( NumStimWaves ) $( cdf+"StimNumpnts" )
	Make /T/O/N=( NumStimWaves ) $( cdf+"DAClist" ), $( cdf+"TTLlist" ), $( cdf+"ADClist" ), $( cdf+"preADClist" )
	
	Wave stimPnts = $cdf+"StimNumpnts"
	Wave /T DAClist = $cdf+"DAClist" // where lists are saved
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T ADClist = $cdf+"ADClist"
	Wave /T preADClist = $cdf+"preADClist"
	
	//String tGainList = StrVarOrDefault( cdf+"TGainList", "" )
	
	//if ( ( strlen( tGainList ) > 0 ) && ( WaveExists( $cdf+"ADCtgain" ) == 1 ) )
	//	Wave ADCtgain = $cdf+"ADCtgain" // telegraph gain
	//	tgain = 1
	//endif
	
	for ( wcnt = 0 ; wcnt < NumStimWaves ; wcnt += 1 )
	
		outs = 0
		ins = 0
		alist = ""
		alist2 = ""
		dlist = ""
		tlist = ""
		
		for ( config = 0 ; config < numpnts( DACname ) ; config += 1 ) // DAC sequence
		
			if ( strlen( DACname[config] ) > 0 )
			
				outs += 1
				chan = WaveValOrDefault( bdf+"DACchan", config, 0 )
				
				if ( ( chan < 0 ) || ( chan > 3 ) ) // 0123
					return ClampAcquireError( "ITCupdateLists Error", "DAC chan out of range : " + num2istr( chan ) )
				endif
				
				wname = sdf + StimWaveName( "DAC", config, wcnt )
				item = wname + "," + num2istr( chan )
				dlist = AddListItem( item, dlist, ";", inf )
				
			endif
			
		endfor

		if ( wcnt < numpnts( DAClist ) )
			DAClist[ wcnt ] = dlist
		else
			return -1
		endif
		
		
		for ( config = 0 ; config < numpnts( TTLname ) ; config += 1 ) // TTL sequence
		
			if ( strlen( TTLname[config] ) > 0 )
			
				chan = WaveValOrDefault( bdf+"TTLchan", config, 0 )
				
				if ( ( chan < 0 ) || ( chan > 15 ) )
					return ClampAcquireError( "ITCupdateLists Error", "TTL chan out of range : " + num2istr( chan ) )
				endif
				
				wname = sdf + StimWaveName( "TTL", config, wcnt )
				item = wname + "," + num2istr( chan )
				tlist = AddListItem( item, tlist, ";", inf )
				
			endif
			
		endfor
		
		if ( wcnt < numpnts( TTLlist ) )
			TTLlist[ wcnt ] = tlist
		else
			return -1
		endif
		
		if ( wcnt < numpnts( stimPnts ) )
			stimPnts[ wcnt ] = ClampWavesNumpnts( dlist, tlist, npnts )
		else
			return -1
		endif
		
		for ( config = 0 ; config < numpnts( ADCname ) ; config += 1 ) // ADC sequence
		
			if ( strlen( ADCname[config] ) > 0 )
			
				chan = WaveValOrDefault( bdf+"ADCchan", config, 0 )
				gain = WaveValOrDefault( bdf+"ADCgain", config, 1 )
				modestr = WaveStrOrDefault( bdf+"ADCmode", config, "" )
	
				if ( ITCrange( gain ) == -1 )
					return ClampAcquireError( "ITCupdateLists Error", "ADC gain value not allowed : " + num2str( gain ) )
				endif
				
				if ( ( chan < 0 ) || ( chan > 7 ) )
					return ClampAcquireError( "ITCupdateLists Error", "ADC chan out of range : " + num2istr( chan ) )
				endif
				
				if ( NMStimADCmodeNormal( modestr ) == 1 ) // normal input
				
					wname = ChanDisplayWave( ins )
					item = wname + "," + num2istr( chan ) + "," + num2str( gain ) + "," + num2istr( config )
					alist = AddListItem( item, alist, ";", inf )
					ins += 1
					
					//if ( ( strlen( tGainList ) > 0 ) && ( numtype( ADCtgain[config] ) == 0 ) )
					//	gain = 1 // full scale
					//	wname = "CT_Tgain" + num2istr( config )
					//	item = wname + "," + num2str( ADCtgain[config] ) + "," + num2str( gain )+ "," + num2istr( 50 ) + "," + num2istr( -1 )
					//	alist2 = AddListItem( item, alist2, ";", inf ) // save as pre-stim input
					//endif
				
				elseif ( strsearch( modestr, "PreSamp=", 0, 2 ) >= 0 ) // pre-sample
				
					wname = "CT_" + WaveStrOrDefault( bdf+"ADCname", config, "" )
					mode = str2num( modestr[8, inf] )
					item = wname + "," + num2istr( chan ) + "," + num2str( gain ) + "," + num2str( mode ) + "," + num2istr( config )
					alist2 = AddListItem( item, alist2, ";", inf )
					
				elseif ( strsearch( modestr, "TGain=", 0, 2 ) >= 0 ) // telegraph gain
				
					tgain = 1
					gain = 1 // full scale
					//mode = ( -1 * mode - 100 )
					wname = "CT_TGain" + num2istr( ClampTGainChan( modestr ) )
					item = wname + "," + num2istr( chan ) + "," + num2str( gain )+ "," + num2istr( tpnts ) + "," + num2istr( -1 )
					alist2 = AddListItem( item, alist2, ";", inf ) // save as pre-stim input
					
				elseif ( StringMatch( modestr[0,0], "T" ) == 1 )
				
					wname = "CT_" + WaveStrOrDefault( bdf+"ADCname", config, "" )
					item = wname + "," + num2istr( chan ) + "," + num2str( gain )+ "," + num2istr( tpnts ) + "," + num2istr( config )
					alist2 = AddListItem( item, alist2, ";", inf ) // save as pre-stim input
					
				endif
			
			endif
			
		endfor

		if ( wcnt < numpnts( ADClist ) )
			ADClist[wcnt] = alist
		else
			return -1
		endif
		
		if ( wcnt < numpnts( preADClist ) )
			preADClist[ wcnt ] = alist2
		else
			return -1
		endif
		
	endfor

	if ( outs < ins ) // extend output lists
	
		if ( outs == 0 )
			nowave = "NoOutput,-1;"
		endif
		
		for ( wcnt = 0 ; wcnt < NumStimWaves ; wcnt += 1 )
			DAClist[wcnt] = ITCextendList( nowave+DAClist[wcnt], ins, 1 )
		endfor
		
	endif
	
	SetNMvar( cdf+"TGainConfig", tgain )
	
	return 0

End // ITCupdateLists

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S ITCseqStr() // create ITC sequence output/input strings ( e.g. "012D", "231D" )

	Variable jcnt, outs, ins, seqnum
	String outseq = "", inseq = "", ttlseq = "", item
	
	String cdf = NMClampDF

	Wave /T DAClist = $cdf+"DAClist"
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T ADClist = $cdf+"ADClist"
	
	if ( numpnts( ADClist ) > 0 )

		for ( jcnt = 0 ; jcnt < ItemsInList( ADClist[ 0 ] ) ; jcnt += 1 )
			item = StringFromList( jcnt, ADClist[ 0 ] ) 
			inseq += StringFromList( 1, item, "," )
		endfor
	
	endif
	
	if ( strlen( inseq ) == 0 )
		inseq = "0" // dummy input
	endif
	
	if ( numpnts( DAClist ) > 0 )
	
		for ( jcnt = 0 ; jcnt < ItemsInList( DAClist[ 0 ] ) ; jcnt += 1 )
		
			item = StringFromList( jcnt, DAClist[ 0 ] )
			seqnum = str2num( StringFromList( 1, item, "," ) )
			
			if ( seqnum >= 0 )
				outseq += StringFromList( 1, item, "," )
			endif
			
		endfor
	
	endif
	
	if ( strlen( outseq ) == 0 )
		outseq = "0" // dummy input
	endif
	
	if ( numpnts( TTLlist ) > 0 )
		for ( jcnt = 0 ; jcnt < ItemsInList( TTLlist[ 0 ] ) ; jcnt += 1 )
			ttlseq = "D"
		endfor
	endif
	
	outs = strlen( outseq )
	ins = strlen( inseq )
	
	if ( outs > ins ) // extend input lists
		inseq = ITCextendList( inseq, outs, 0 )
	elseif ( ins > outs )
		outseq = ITCextendList( outseq, ins, 0 )
	endif
	
	return outseq + ttlseq + ";" + inseq + ttlseq 

End // ITCseqStr

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S ITCextendList( list, extend2, listType )
	String list
	Variable extend2
	Variable listType // ( 0 ) string list "0121" ( 1 ) item list "item1;item2;"

	Variable ccnt, length
	String item
	
	if ( listType == 0 ) // string list "012"
	
		 length = strlen( list )
	
		if ( ( length > 0 ) && ( length < extend2 ) )
		
			for ( ccnt = 0 ; ccnt < extend2 ; ccnt += 1 )
			
				list += list[ccnt, ccnt]
				length = strlen( list )
				
				if ( length == extend2 )
					break
				endif
				
			endfor
			
		endif
		
	elseif ( listType == 1 ) // item list "wave0;wave1;wave2;"
	
		length = ItemsInlist( list )
		
		if ( ( length > 0 ) && ( length < extend2 ) )
		
			for ( ccnt = 0 ; ccnt < extend2 ; ccnt += 1 )
			
				item = StringFromList( ccnt, list )
				list = AddListItem( item, list, ";", inf )
				length = ItemsInlist( list )
				
				if ( length == extend2 )
					break
				endif
				
			endfor
			
		endif
	
	endif
	
	return list
	
End // ITCextendList

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCmakeWaves( NumOuts, NumStimWaves, InterStimTime, NumStimReps, InterRepTime, AcqMode )
	Variable NumOuts, NumStimWaves, InterStimTime, NumStimReps, InterRepTime, AcqMode
	
	Variable icnt, wcnt, stimN, repN, insertN, pipe, error, npnts
	String item, wname, wlist = "", tlist = ""
	
	String cdf = NMClampDF, sdf = StimDF()
	
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 0 )
	String precision = StrVarOrDefault( cdf+"WavePrecision", "S" ) // ITC waves have to be single precision

	if ( WaveExists( $cdf+"DAClist" ) == 0 )
		return ClampAcquireError( "ITCmakeWaves Error", "missing wave " + cdf + "DAClist" )
	endif
	
	if ( WaveExists( $cdf+"TTLlist" ) == 0 )
		return ClampAcquireError( "ITCmakeWaves Error", "missing wave " + cdf + "TTLlist" )
	endif
	
	if ( WaveExists( $cdf+"ADClist" ) == 0 )
		return ClampAcquireError( "ITCmakeWaves Error", "missing wave " + cdf + "ADClist" )
	endif
	
	Wave /T DAClist = $cdf+"DAClist"
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T ADClist = $cdf+"ADClist"
	Wave /T preADClist = $cdf+"preADClist"
	Wave stimPnts = $cdf+"StimNumpnts"
	
	pipe = ITCpipeDelay( NumOuts )
	
	if ( AcqMode == 0 ) // epic precise
	
		if ( InterStimTime > 0 )
			stimN = floor( InterStimTime / SampleInterval )
		endif
		
		if ( ( NumStimReps > 1 ) && ( InterRepTime > 0 ) )
			repN = floor( InterRepTime / SampleInterval )
		endif
	
	endif
	
	for ( wcnt = 0 ; wcnt < NumStimWaves ; wcnt += 1 )
	
		if ( wcnt < numpnts( DAClist ) )
			wlist = DAClist[ wcnt ]
		else
			wlist = ""
		endif
		
		if ( wcnt < numpnts( TTLlist ) )
			tlist = TTLlist[ wcnt ]
		else
			tlist = ""
		endif

		if ( stimN > 0 )
			InsertN = stimN
		else
			InsertN = 0
		endif
		
		if ( ( wcnt == 0 ) && ( repN > 0 ) )
			insertN += repN
		endif
		
		wname = sdf + "ITCoutWave" + num2istr( wcnt )
		
		if ( !WaveExists( $wname ) && ( wcnt < numpnts( StimPnts ) ) )
		
			switch( AcqMode )
			
				case 0: // epic precise
			
					if ( insertN >= pipe )
						error = ITCmixWaves( wname, NumOuts, wlist, tlist, stimPnts[wcnt], insertN, 1, pipe ) // mix output waves, shift
					else
						return ClampAcquireError( "ITCmakeWaves Error", "inter-wave or inter-rep time too short. Try continuous acquisition." )
					endif
					
					break
					
				case 1: // continuous
				case 4: // continuous triggered
					error = ITCmixWaves( wname, NumOuts, wlist, tlist, stimPnts[wcnt], insertN, 1, 0 ) // mix output waves, no shift
					break
					
				case 2: // episodic
				case 3: // triggered
					error = ITCmixWaves( wname, NumOuts, wlist, tlist, stimPnts[wcnt], insertN, 1, pipe )
					break
					
				default:
					error = -1
					
			endswitch
		
		endif
		
		if ( error < 0 )
			return ClampAcquireError( "ITCmakeWaves Error", "mix wave error" )
		endif
			
		npnts = numpnts( $wname ) // number of points made for ITCoutWave
		
		// make input waves
		
		wname = sdf + "ITCinWave" + num2istr( wcnt )
		Make /O/N=( npnts ) $wname = Nan
		
		if ( ( wcnt < numpnts( ADClist ) ) && ( wcnt < numpnts( stimPnts ) ) )
			for ( icnt = 0 ; icnt < ItemsInList( ADClist[wcnt] ) ; icnt += 1 )
				item = StringFromList( icnt, ADClist[wcnt] )
				wname = StringFromList( 0, item, "," )
				Make /O/N=( stimPnts[wcnt] ) $wname = Nan
				Setscale /P x 0, SampleInterval, $wname
			endfor
		endif
		
		if ( wcnt < numpnts( preADClist ) )
			for ( icnt = 0 ; icnt < ItemsInList( preADClist[wcnt] ) ; icnt += 1 )
				item = StringFromList( icnt, preADClist[wcnt] )
				wname = StringFromList( 0, item, "," )
				npnts = str2num( StringFromList( 3, item, "," ) )
				Make /O/N=( npnts ) $wname = Nan
			endfor
		endif
		
	endfor

End // ITCmakeWaves

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCkillWaves() // Kill ITC waves that may exist
	
	Variable icnt
	String sdf = StimDF()
	String wname, wlist = NMFolderWaveList( sdf, "ITC*", ";", "", 0 )
		
	for ( icnt = 0 ; icnt < ItemsInList( wlist ) ; icnt += 1 )
		wname = StringFromList( icnt, wlist )
		KillWaves /Z $sdf+wname
	endfor

End // ITCkillWaves

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCpipeDelay( seqnum )
	Variable seqnum // number of inputs in ITC sequence command
	Variable pipe = 3 // one input
	
	if ( seqnum > 1 )
		pipe = 2*seqnum // pipeline delay for more than one input
	endif
	
	return pipe

End // ITCpipeDelay

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ITCmixWaves( mixwname, nmix, wlist, tlist, npnts, ipnts, mixflag, pipedelay )
	String mixwname // the mixed wave to be made
	Variable nmix // number of waves in mixed wave
	String wlist // wave name list
	String tlist // TTL wave name list
	Variable npnts // points in waves
	Variable ipnts // points to insert
	Variable mixflag // ( 1 ) mix ( -1 ) unmix
	Variable pipedelay // FIFO pipeline delay value

	Variable icnt, jcnt, kcnt, allpnts, numTTL, chan, gain, np, gscale
	String item, wname
	
	String cdf = NMClampDF, sdf = StimDF()
	
	numTTL = ItemsInList( tlist )
	
	if ( ( numtype( npnts ) > 0 ) || ( npnts <= 0 ) )
		return -1
	endif
	
	if ( mixflag == 1 ) // mix waves

		allpnts = npnts*nmix
		
		Make /O/N=( allpnts ) $mixwname = 0
		
		Wave mixWave = $mixwname

		for ( icnt = 0 ; icnt < ItemsInList( wlist ) ; icnt += 1 ) // mix DAC waves
			
			item = StringFromList( icnt, wlist )
			wname = StringFromList( 0, item, "," )
			chan = str2num( StringFromList( 1, item, "," ) )
	
			if ( ( WaveExists( $wname ) == 0 ) || ( chan < 0 ) )
				Make /O/N=( npnts ) $wname = 0
			endif
			
			Wave tempWave = $wname

			kcnt = 0
			
			for ( jcnt = icnt ; jcnt < numpnts( mixWave ) ; jcnt += nmix )
			
				if ( kcnt >= numpnts( tempWave ) )
					break
				endif
				
				mixWave[ jcnt ] = tempWave[ kcnt ]
				kcnt += 1
				
			endfor
			
		endfor
		
		gscale = ITCrange( 1 )
		
		if ( gscale < 0 )
			return -1
		endif
		
		mixWave *= 32768 / gscale // convert DAC output to bits ( 32768 bits/10.24 volt )
		
		if ( numTTL > 0 )
		
			Make /O/N=( npnts ) $( sdf+"ITCTTLOUT" ) = 0
			
			Wave TTLout = $sdf+"ITCTTLOUT"
		
			for ( icnt = 0 ; icnt < numTTL ; icnt += 1 ) // sum TTL output "D" together
			
				item = StringFromList( icnt, tlist )
				wname = StringFromList( 0, item, "," )
				chan = str2num( StringFromList( 1, item, "," ) )

				if ( ( WaveExists( $wname ) == 0 ) || ( chan < 0 ) )
					Make /O/N=( npnts ) $wname = 0
				endif
				
				Wave tempwave = $wname
				
				Wavestats /Q tempwave
				
				if ( ( numtype( V_max ) == 0 ) && ( V_max != 0 ) ) // GJ
				
					tempwave /= V_max // normalize wave
					tempwave *= 2^( chan ) // set channel bit value
					
					TTLout += tempwave
				
				endif
				
			endfor
			
			kcnt = 0
			
			for ( jcnt = nmix-1 ; jcnt < numpnts( mixWave ) ; jcnt += nmix )
			
				if ( kcnt >= numpnts( TTLout ) )
					break
				endif
				
				mixWave[ jcnt ] = TTLout[ kcnt ]
				kcnt += 1
				
			endfor
		
		endif
		
		InsertPoints 0, ( ipnts*nmix ), mixWave // insert delay points for episodic timing
		
		if ( pipedelay > 0 )
			Rotate -pipedelay, mixWave // shift for pipeline delay
		endif

	elseif ( mixflag == -1 ) // unmix waves
	
		if ( WaveExists( $mixwname ) == 0 )
			return -1
		endif
	
		Wave mWave = $mixwname
		
		allpnts = numpnts( $mixwname )
		
		ipnts = allpnts - npnts*nmix
		
		if ( pipedelay > 0 )
			Rotate -pipedelay, mWave
		endif
		
		Duplicate /O/R=[ipnts,ipnts+npnts*nmix-1] $mixwname $( sdf + "ITCmix" )

		Wave mixWave = $sdf + "ITCmix"

		for ( icnt = 0 ; icnt < ItemsInList( wlist ) ; icnt += 1 )
		
			item = StringFromList( icnt, wlist )
			wname = StringFromList( 0, item, "," )
			chan = str2num( StringFromList( 1, item, "," ) )
			gain = str2num( StringFromList( 2, item, "," ) )

			if ( ( WaveExists( $wname ) == 0 ) || ( chan < 0 ) )
				continue
			endif
			
			Redimension /N=( npnts ) $wname
			
			Wave tempWave = $wname
			
			tempWave = 0
			kcnt = 0

			for ( jcnt = icnt ; jcnt < numpnts( mixWave ) ; jcnt += nmix )
			
				if ( kcnt >= numpnts( tempWave ) )
					break
				endif
				
				tempWave[ kcnt ] = mixWave[ jcnt ]
				kcnt += 1
				
			endfor
			
			gscale = ITCrange( gain )
			
			if ( gscale > 0 )
				tempWave /= 32768 / gscale // convert to volts
			endif
			
		endfor
	
	endif
	
	KillWaves /Z NoOutput
	
	return 0

End // ITCmixWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCrange( scale )
	Variable scale

	switch( scale )
		case 1:
			return 10.24 // mV
		case 2:
			return 5.12
		case 5:
			return 2.048
		case 10:
			return 1.024
	endswitch
	
	return -1

End // ITCrange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ITCrangeStr( scale )
	Variable scale

	switch( scale )
		case 1:
			return "10"
		case 2:
			return "5"
		case 5:
			return "2"
		case 10:
			return "1"
	endswitch
	
	return "error"
	
End // ITCrangeStr

//****************************************************************
//****************************************************************
//****************************************************************

Function ITCSetDAC( chan, volts )
	Variable chan
	Variable volts
	
	String cdf = NMClampDF, sdf = StimDF()
	
	String aboard = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	Execute aboard + "SetDAC " + num2istr( chan ) + "," + num2str( volts )
	
End // ITCSetDAC

//****************************************************************
//****************************************************************
//****************************************************************





