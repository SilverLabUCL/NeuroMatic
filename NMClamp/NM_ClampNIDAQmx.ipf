#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//#pragma hide = 1
// SetIgorOption IndependentModuleDev = 1
//
//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic NIDAQmx Clamp Functions
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro 4
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//	Created in the Laboratory of Dr. Angus Silver
//	Department of Physiology, University College London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 July 2003
//
//****************************************************************
//****************************************************************
//****************************************************************

#if exists("DAQmx_WaveformGen")

Static Constant NM_NIDAQCounter = 0 // default counter number
Static Constant NM_NidaqDIOPort = 0 // port with buffered DIO
Static Constant NM_NidaqDACMinVoltage = -10 // DAC voltage range ( some users may need to change this to -5 volts )
Static Constant NM_NidaqDACMaxVoltage = 10 // DAC voltage range ( some users may need to change this to 5 volts )

Static StrConstant NM_NidaqADCChannelType = ""		// ""			NIDAQ device default
													// "Diff"		differential
													// "RSE"		referenced singled-ended
													// "NRSE"	non-referenced single-ended
													// "PDIFF"	pseudo-differential

//****************************************************************
//****************************************************************
//****************************************************************

Menu "NeuroMatic", dynamic

	"-"
	
	SubMenu "NIDAQ"
		"NIDAQ Reset", NidaqResetAll()
		"NIDAQ FIFO Import", NIDAQ_FIFO_Import()
		"NIDAQ FIFO Chart", NIDAQ_FIFO_Chart_Call()
		"NIDAQ Error String", NidaqErrorPrint()
	ENd

End // Neuromatic menu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NidaqExtTrigger()

	return "/" + NidaqBoardName( 0 ) + "/pfi0" // default external trigger

End // NidaqExtTrigger

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NidaqErrorPrint()

	Print fDAQmx_ErrorString()

End // NidaqErrorPrint

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqErrorCheck( mssg )
	String mssg
	
	String rte = GetRTErrMessage()
	String nqe = ""

	if ( GetRTError( 1 ) == 0 )
		return 0
	endif
	
	nqe = fDAQmx_ErrorString()
	
	Print ""
	ClampError( 0, mssg )
	
	if ( strlen( rte ) > 0 )
		Print "Igor Runtime Error:" + rte
	endif
	
	if ( strlen( nqe ) > 0 )
		Print "NIDAQ error:" + nqe
	endif
	
	Print ""
	
	return -1
	
End // NidaqErrorCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NidaqBoardName( boardNum )
	Variable boardNum
	
	String bList = fDAQmx_DeviceNames()
	
	if ( ItemsInList( bList ) == 0 )
		return ""
	elseif ( ItemsInList( bList ) == 1 )
		return StringFromList( 0, bList )
	endif
	
	boardNum = NidaqBoardNumCheck( boardNum )
	
	return StringFromList( boardNum-1, bList )

End // NidaqBoardName

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqBoardNumCheck( boardNum )
	Variable boardNum
	
	String bList = fDAQmx_DeviceNames()
	Variable driver = NumVarOrDefault( NMClampDF+"BoardDriver",0 )
	
	if ( ItemsInList( bList ) == 0 )
		return -1
	elseif ( ItemsInList( bList ) == 1 )
		return 1
	endif
	
	if ( ( boardNum == 0 ) && ( driver > 0 ) && ( driver <= ItemsInList( bList ) ) )
		return driver // default board number
	elseif ( ( boardNum > 0 ) && ( boardNum <= ItemsInList( bList ) ) )
		return boardNum
	endif
	
	return 1

End // NidaqBoardNumCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqConfig()

	NidaqBoardList()
	
	return 0

End // NidaqConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NidaqBoardList()

	Variable icnt
	String bname, numList = "", bList = fDAQmx_DeviceNames()

	if ( ItemsInList( bList ) == 0 )
		ClampError( 1, "located no NIDAQ boards" )
		return ""
	endif
	
	//for ( icnt = 0 ; icnt < ItemsInList( bList ) ; icnt += 1 )
	//	bname = num2istr( icnt+1 ) + "," + StringFromList( icnt, bList )
	//	numList = AddListItem( bname, numList, ";", inf )
	//endfor
	
	//SetNMStr( NMClampDF+"BoardList", numList )
	
	SetNMStr( NMClampDF+"BoardList", bList )
	
	return bList

End // NidaqBoardList

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqStimCheck()

	Variable icnt, config, bnum, acqMode, minintvl = 9999
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	String adcList = NMStimBoardConfigActiveList( sdf, "ADC" )
	String dacList = NMStimBoardConfigActiveList( sdf, "DAC" )
	String ttlList = NMStimBoardConfigActiveList( sdf, "TTL" )
	
	if ( WaveExists( $bdf+"ADCname" ) == 0 )
		return ClampError( 1, "Cannot locate stimulus board configs in data folder " + bdf )
	endif
	
	// check sample intervals
	
	//for ( icnt = 0 ; icnt < ItemsInList( adcList ) ; icnt += 1 )
		//config = str2num( StringFromList( icnt, adcList ) )
		//bnum = WaveValOrDefault( bdf+"ADCboard", config, 0 )
		//minintvl = min( minintvl, StimIntervalGet( sdf, bnum ) )
		//minintvl = min( minintvl, NMStimSampleInterval( sdf ) )
	//endfor
	
	//for ( icnt = 0 ; icnt < ItemsInList( dacList ) ; icnt += 1 )
		//config = str2num( StringFromList( icnt, dacList ) )
		//bnum = WaveValOrDefault( bdf+"DACboard", config, 0 )
		//minintvl = min( minintvl, StimIntervalGet( sdf, bnum ) )
		//minintvl = min( minintvl, NMStimSampleInterval( sdf ) )
	//endfor
	
	//NidaqIntervalCheck( minintvl )
	
	// check acquisition mode
	
	acqMode = NumVarOrDefault( sdf+"AcqMode", -1 )
	
	switch( acqMode )
	
		case 0: // episodic precise timers
		case 2: // episodic non-precise timers
		case 3: // episodic triggered
			break
			
		case 1: // continuous
		case 4: // continuous triggered
			break
			//return ClampError( 1, "NIDAQ continuous acquisition not supported" )
			//return -1
		
		default:
			return ClampError( 1, "NIDAQ acquisition mode not recognized : " + num2istr( acqMode ) )
			
	endswitch
	
	// check TTL configuration
	
	if ( ItemsInList( ttlList ) > 0 )
		//ClampError( 1, "NIDAQ TTL not supported" )
		//Print "Error: NIDAQ TTL waveform generation is currently not supported by NeuroMatic. Use 5 Volt DAC pulses as an alternative."
		//return -1
	endif
	
	return 0

End // NidaqStimCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqIntervalCheck( intvl ) // CANNOT locate NIDAQmx functions for this
	Variable intvl
	
	Variable lmt = 0.0000001 // fNIDAQ_SetUpdateLimit( 0 )
	
	intvl /= 1000

	if ( ( intvl < lmt ) && ( intvl < 0.0001 ) )
		DoAlert 0, "Warning: NIDAQ sample rates less than 10 kHz should be used with caution."
		//fNIDAQ_SetUpdateLimit( intvl )
	else
		//fNIDAQ_SetUpdateLimit( lmt )
	endif
	
End // NidaqIntervalCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqResetAll()

	NidaqResetBoard( -1, 1 )
	
End // NidaqResetAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqResetBoard( boardNum, resetType )
	Variable boardNum // ( -1 ) for all
	Variable resetType // ( 0 ) soft ( 1 ) hard
	
	Variable icnt, ibgn, iend
	String bname, bList = fDAQmx_DeviceNames()
	
	if ( boardNum == -1 )
		ibgn = 0
		iend = ItemsInList( bList ) - 1
	else
		ibgn = boardNum
		iend = boardNum
	endif
	
	for ( icnt = ibgn ; icnt <= iend ; icnt += 1 )
		
		bname = StringFromList( icnt, bList )
		
		if ( resetType == 0 )
			fDAQmx_ScanStop( bname )
			fDAQmx_WaveformStop( bname )
			fDAQmx_CTR_Finished( bname, NM_NIDAQCounter )
		elseif ( resetType == 1 )
			fDAQmx_ResetDevice( bname )
		endif
	
	endfor
	
	if ( NidaqErrorCheck( "NidaqResetBoard" ) < 0 )
		return -1
	endif
	
	return 0
	
End //NidaqResetBoard

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqAcquire( mode, saveWhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) test timers
	Variable saveWhen // ( 0 ) never ( 1 ) after ( 2 ) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime

	Variable nwaves, error
	String cdf = NMClampDF, sdf = StimDF()
	
	Variable acqMode = NumVarOrDefault( sdf+"AcqMode", -1 )
	
	NidaqResetAll()
	
	if ( NidaqStimCheck() != 0 )
		return -1
	endif
	
	nwaves = NumStimWaves * NumStimReps // total number of waves
	
	if ( NidaqUpdateLists() < 0 )
		return -1
	endif
	
	//NidaqUpdateListsPN()
	
	if ( ClampAcquireStart( mode, nwaves ) < 0 )
		return -1
	endif
	
	NidaqDacTimeScale( 0.001 ) // convert to seconds
	//NidaqWavesInput( nwaves ) // moved to allow RandomOrder
	NidaqMakeADCpre( nwaves )
	
	if ( ( NumStimWaves == 1 ) && ( NumStimReps > 1 ) )
		NumStimWaves = NumStimReps
		//interStimTime = interRepTime
		NumStimReps = 1
		//interRepTime = 0
	endif
	
	SetNMVar( cdf+"PRTmode", mode )
	SetNMVar( cdf+"SaveWhen", saveWhen )
	SetNMVar( cdf+"WaveLength", WaveLength )
	SetNMVar( cdf+"NumStimWaves", NumStimWaves )
	SetNMVar( cdf+"InterStimTime", InterStimTime )
	SetNMVar( cdf+"NumStimReps", NumStimReps )
	SetNMVar( cdf+"InterRepTime", InterRepTime )
	SetNMVar( cdf+"NumWaves", NumStimWaves*NumStimReps )
	
	switch( acqMode )
	
		case 0: // epic presice
		case 2: // episodic
		case 3: // epic triggered
			error = NidaqAcqEpics()
			NidaqDacTimeScale( 1 ) // convert to msec
			NidaqResetBoard( -1, 0 )
			ClampAcquireFinish( mode, saveWhen, 1 )
			break
			
		case 1: // continuous
		case 4: // continuous triggered
			NidaqMakeADC()
			error = NIDAQAcqContinuous()
			break

	endswitch
	
	return error

End // NidaqAcquire

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqAcqEpics()

	Variable nwaves, icnt, rcnt, wcnt, wcnt2, bcnt, ccnt
	Variable chan, scale, config, onewave, start, tgainv, currentWave
	Variable tgainChan, tscale
	
	String wname, bname, dname, xlist, alist, olist, tlist, wlist, instr, itemstr, modeStr
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	String bList = fDAQmx_DeviceNames()
	String trig = "", driver = "", lastOUT = "", lastADC = "", extTrig = NidaqExtTrigger()
	
	Variable mode = NumVarOrDefault( cdf+"PRTmode", 0 )
	Variable saveWhen = NumVarOrDefault( cdf+"SaveWhen", 0 )
	Variable WaveLength = NumVarOrDefault( cdf+"WaveLength", 0 )
	Variable NumStimWaves = NumVarOrDefault( cdf+"NumStimWaves", 0 )
	Variable InterStimTime = NumVarOrDefault( cdf+"InterStimTime", 0 )
	Variable NumStimReps = NumVarOrDefault( cdf+"NumStimReps", 0 )
	Variable InterRepTime = NumVarOrDefault( cdf+"InterRepTime", 0 )
	
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 1 )
	Variable acqMode = NumVarOrDefault( sdf+"AcqMode", -1 )
	Variable tGainConfig = NumVarOrDefault( cdf+"TGainConfig", 0 )
	
	Variable /G V_DAQmx_DIO_TaskNumber = -1
	
	if ( WaveExists( $bdf+"ADCscale" ) == 0 )
		return -1
	endif
	
	Wave ADCscale = $bdf+"ADCscale"
	Wave ADCchan = $bdf+"ADCchan"
	Wave ADCtgain = $bdf+"ADCtgain"
	Wave /T ADCmode = $bdf+"ADCmode"
	
	Wave /T preADClist = $cdf+"preADClist"
	
	//if ( ClampPN() == 0 )
		Wave /T TTLlist = $cdf+"TTLlist"
		Wave /T DAClist = $cdf+"DAClist"
		Wave /T ADClist = $cdf+"ADClist"
	//else
		//Wave /T TTLlist = $cdf+"TTLlistPN"
		//Wave /T DAClist = $cdf+"DAClistPN"
		//Wave /T ADClist = $cdf+"ADClistPN"
	//endif
	
	nwaves = NumStimWaves * NumStimReps // total number of waves
	
	for ( wcnt = 0 ; wcnt < DimSize( ADClist, 0 ) ; wcnt += 1 )
	for ( bcnt = 0 ; bcnt < DimSize( ADClist, 1 ) ; bcnt += 1 )
	
		bname = StringFromList( bcnt, bList )
		ccnt = fDAQmx_NumCounters( bname )
		
		alist = ADClist[wcnt][bcnt]
		
		if ( ItemsInList( alist ) > 0 )
			lastADC = bname
			if ( ccnt > 1 )
				driver = bname
			endif
		endif
		
		olist = DAClist[wcnt][bcnt]
		
		if ( ItemsInList( olist ) > 0 )
			lastOUT = bname
			if ( ccnt > 1 )
				driver = bname
			endif
		endif
		
		olist = TTLlist[wcnt][bcnt]
		
		if ( ItemsInList( olist ) > 0 )
			lastOUT = bname
			if ( ccnt > 1 )
				driver = bname
			endif
		endif
				
	endfor
	endfor
	
	if ( ( strlen( lastADC ) == 0 ) || ( strlen( driver ) == 0 ) )
		return ClampError( 1, "NIDAQ board config error" )
	endif
	
	if ( DimSize( ADClist, 0 ) == 1 )
		onewave = 1
	endif
	
	for ( bcnt = 0 ; bcnt < DimSize( preADClist, 1 ) ; bcnt += 1 )
	
		// moved pre-scan before reps loop 18 March 2009, due to delays
			
		alist = preADClist[wcnt2][bcnt] // driver ADC
		bname = StringFromList( bcnt, bList )
		
		if ( ItemsInList( alist ) > 0 )
			
			if ( NidaqPreScan( bname, alist ) < 0 )
				return -1
			endif
			
		endif
	
	endfor
	
	if ( tGainConfig )
		ClampTGainScaleValue( bdf )
	endif
	
	for ( rcnt = 0 ; rcnt < NumStimReps ; rcnt += 1 ) // loop thru reps
	
		// start scan clock on counter 0
		if ( ( acqMode == 0 ) && ( rcnt == 0 ) || ( InterRepTime > 0 ) )
			if ( NidaqStartCounter( driver, NM_NIDAQCounter, WaveLength, InterStimTime ) != 0 )
				return ClampError( 1, "Error in configuration of NIDAQ Counter " + num2str( NM_NIDAQCounter ) )
			endif
		endif
		
		NidaqMakeADC() // added this fxn here to allow RandomOrder

		for ( wcnt = 0 ; wcnt < NumStimWaves ; wcnt += 1 ) // loop thru waves
		
			currentWave = CurrentNMWave()
			
			wcnt2 = wcnt
			
			if ( onewave == 1 )
				wcnt2 = 0
			endif
			
			for ( bcnt = 0 ; bcnt < DimSize( TTLlist, 1 ) ; bcnt += 1 )
			
				bname = StringFromList( bcnt, bList )
				olist = TTLlist[wcnt2][bcnt]
				
				if ( ItemsInList( olist ) > 0 )
				
					if ( V_DAQmx_DIO_TaskNumber >= 0 )
						fDAQmx_DIO_finished( bname, V_DAQmx_DIO_TaskNumber )
					endif
					
					trig = "/" + driver + "/ai/sampleclock"
					
					wlist = ""
					xlist = ""
					
					for ( icnt = 0 ; icnt < ItemsInList( olist, ";" ) ; icnt += 1 )
						itemstr = StringFromList( 0, StringFromList( icnt, olist, ";" ), "," )
						wlist = AddListItem( itemstr, wlist, ",", inf )
						itemstr = StringFromList( 1, StringFromList( icnt, olist, ";" ), "," )
						itemstr = "/" + bname + "/port" + num2istr( NM_NidaqDIOPort ) + "/line" + itemstr
						xlist = AddListItem( itemstr, xlist, ",", inf )
					endfor
					
					icnt = strlen( wlist ) - 1
					wlist[ icnt, icnt ] = ""
					
					icnt = strlen( xlist ) - 1
					xlist[ icnt, icnt ] = ""
					
					Execute "DAQmx_DIO_Config /Dev=\"" + bname + "\" /LGRP=1 /DIR=1 /CLK={\"" + trig + "\", 1} /WAVE={" + wlist + "} \"" + xlist + "\""
					
				endif
				
			endfor
			
			if ( NidaqErrorCheck( "NidaqAcqEpics" ) < 0 )
				return -1
			endif
			
			start = 0
			
			for ( bcnt = 0 ; bcnt < DimSize( DAClist, 1 ) ; bcnt += 1 )
			
				bname = StringFromList( bcnt, bList )
				olist = DAClist[wcnt2][bcnt]
				
				if ( ItemsInList( olist ) > 0 )
				
					switch( acqMode )
					
						case 0: // epic precise
							start = 1
							trig = "/" + driver + "/Ctr0InternalOutput"
							DAQmx_WaveformGen /DEV=bname /NPRD=1 /TRIG={trig} olist
							break
							
						case 2: // episodic
							if ( StringMatch( bname, lastOUT ) == 1 )
								start = 1
								DAQmx_WaveformGen /DEV=bname /STRT=0 olist
							else
								trig = "/" + lastOUT + "/ao/starttrigger"
								DAQmx_WaveformGen /DEV=bname /NPRD=1 /TRIG={trig} olist
							endif
							break
							
						case 3: // triggered
							start = 1
							DAQmx_WaveformGen /DEV=bname /NPRD=1 /TRIG={extTrig} olist
							break
							
					endswitch
					
				endif
				
			endfor
			
			if ( NidaqErrorCheck( "NidaqAcqEpics" ) < 0 )
				return -1
			endif
				
			for ( bcnt = 0 ; bcnt < DimSize( ADClist, 1 ) ; bcnt += 1 )
			
				bname = StringFromList( bcnt, bList )
				alist = ADClist[wcnt2][bcnt]
				
				if ( ItemsInList( alist ) > 0 )
				
					switch( acqMode )
					
						case 0: // epic precise
						
							if ( StringMatch( bname, lastADC ) == 1 )
								if ( start == 1 )
									trig = "/" + lastOUT + "/ao/starttrigger"
									DAQmx_Scan /DEV=bname /TRIG={trig} WAVES=NidaqScanList( alist )
								else
									trig = "/" + driver + "/Ctr0InternalOutput"
									DAQmx_Scan /DEV=bname /TRIG={trig} WAVES=NidaqScanList( alist )
								endif
							else
								if ( start == 1 )
									trig = "/" + lastOUT + "/ao/starttrigger"
									DAQmx_Scan /DEV=bname /BKG /TRIG={trig} WAVES=NidaqScanList( alist )
								else
									trig = "/" + driver + "/Ctr0InternalOutput" 
									DAQmx_Scan /DEV=bname /BKG /TRIG={trig} WAVES=NidaqScanList( alist )
								endif
							endif
							
							break
							
						case 2: // episodic
						
							if ( StringMatch( bname, lastADC ) == 1 )
								if ( start == 1 )
									trig = "/" + lastOUT + "/ao/starttrigger"
									DAQmx_Scan /DEV=bname /BKG /TRIG={trig} WAVES=NidaqScanList( alist )
								else
									start = 2
									DAQmx_Scan /DEV=bname /STRT=0 WAVES=NidaqScanList( alist )
								endif
							else
								if ( start == 1 )
									trig = "/" + lastOUT + "/ao/starttrigger"
									DAQmx_Scan /DEV=bname /BKG /TRIG={trig} WAVES=NidaqScanList( alist )
								else
									trig = "/" + lastADC + "/ai/starttrigger"
									DAQmx_Scan /DEV=bname /BKG /TRIG={trig} WAVES=NidaqScanList( alist )
								endif
							endif
							
							break
							
						case 3: // triggered
						
							if ( StringMatch( bname, lastADC ) == 1 )
								if ( start == 1 )
									trig = "/" + lastOUT + "/ao/starttrigger"
									DAQmx_Scan /DEV=bname /TRIG={trig} WAVES=NidaqScanList( alist )
								else
									DAQmx_Scan /DEV=bname /TRIG={extTrig} WAVES=NidaqScanList( alist )
								endif
							else
								if ( start == 1 )
									trig = "/" + lastOUT + "/ao/starttrigger"
									DAQmx_Scan /DEV=bname /BKG /TRIG={trig} WAVES=NidaqScanList( alist )
								else
									trig = "/" + lastADC + "/ai/starttrigger"
									DAQmx_Scan /DEV=bname /BKG /TRIG={trig} WAVES=NidaqScanList( alist )
								endif
							endif
							break
							
					endswitch
					
				endif
			
			endfor
			
			if ( NidaqErrorCheck( "NidaqAcqEpics" ) < 0 )
				return -1
			endif
			
			if ( acqMode == 2 )
			
				switch( start )
					case 1:
						fDAQmx_WaveformStart( lastOUT, 1 )
						break
					case 2:
						fDAQmx_ScanStart( lastADC, 2 )
						break
				endswitch
				
				fDAQmx_ScanWait( lastADC )
				
			endif
			
			if ( NidaqErrorCheck( "NidaqAcqEpics" ) < 0 )
				return -1
			endif
			
			// save inputs to waves
			
			for ( bcnt = 0 ; bcnt < DimSize( ADClist, 1 ) ; bcnt += 1 )
			
				bname = StringFromList( bcnt, bList )
				alist = ADClist[wcnt2][bcnt]
			
				for ( ccnt = 0 ; ccnt < ItemsInList( alist ) ; ccnt += 1 )
					
					xlist = StringFromList( ccnt,alist )
					dname = StringFromList( 0,xlist,"," )
					chan = str2num( StringFromList( 1,xlist,"," ) )
					config = str2num( StringFromList( 3,xlist,"," ) )
					
					modeStr = ADCmode[ config ]
					
					if ( mode == 1 )
						wname = GetWaveName( "default", ccnt,  currentWave )
					else
						wname = GetWaveName( "default", ccnt, 0 )
					endif
					
					if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
						scale = NMMultiClampADCNum( sdf, config, "scale" )
					else
						scale = ADCscale[ config ]
					endif
					
					if ( ( numtype( scale ) > 0 ) || ( scale <= 0 ) )
						scale = 1
					endif
					
					Wave wtemp = $dname
					wtemp /= scale
					
					Duplicate /O wtemp $wname
					
					Setscale /P x 0, SampleInterval, $wname // change x-scale to msec
					
					Note $wname, "Scale Factor:" + num2str( scale )
					
					//wname = ClampPNsubtraction( wname, ccnt, currentWave )
					
					if ( WaveExists( $wname ) == 1 )
					
						ChanWaveMake( ccnt, wname, ChanDisplayWave( ccnt ), xWave = "" ) // make display wave
						
						if ( NumVarOrDefault( ChanDF( ccnt )+"overlay", 0 ) > 0 )
							ChanOverlayUpdate( ccnt )
						endif
			
						if ( ( mode == 1 ) && ( saveWhen == 2 ) )
							ClampNMBAppend( wname ) // update waves in saved folder
						endif
					
					endif
					
				endfor
			
			endfor
			
			ClampAcquireNext( mode, nwaves )
	
			//if ( ( acqMode == 2 ) && ( NidaqWait( driver, NM_NIDAQCounter, NM_NIDAQCounter+1, InterStimTime ) < 0 ) )
			if ( ( acqMode == 2 ) && ( ClampWaitMSTimer( InterStimTime ) < 0 ) )
				return ClampError( 1, "NIDAQWait Clock Error" )
			endif
			
			if ( NMProgressCancel() == 1 )
				break
			endif
		
		endfor // waves

		if ( rcnt < NumStimReps - 1 )
			//if ( NidaqWait( driver, NM_NIDAQCounter, NM_NIDAQCounter+1, InterRepTime ) < 0 )
			if ( ClampWaitMSTimer( InterRepTime ) < 0 )
				return ClampError( 1, "NIDAQWait Clock Error" )
			endif
		endif
		
		if ( NMProgressCancel() == 1 )
			break
		endif
	
	endfor // reps
	
	KillVariables /Z V_DAQmx_DIO_TaskNumber
	
	return 0

End // NidaqAcqEpics

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqPreScan( boardName, acqlist )
	String boardName
	String acqlist
	
	Variable icnt, nnct, chan, gain, npnts, ncnt, config, scale

	String xlist, wname
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )

	String precision = StrVarOrDefault( cdf+"WavePrecision", "D" )
	
	for ( icnt = 0 ; icnt < ItemsInList( acqlist ) ; icnt += 1 )
	
		xlist = StringFromList( icnt,acqlist )
		wname = StringFromList( 0,xlist,"," )
		chan = str2num( StringFromList( 1,xlist,"," ) )
		gain = str2num( StringFromList( 2,xlist,"," ) )
		npnts = str2num( StringFromList( 3,xlist,"," ) )
		config = str2num( StringFromList( 4,xlist,"," ) )
		
		scale = WaveValOrDefault( bdf+"ADCscale", config, 1 )
		
		if ( ( numtype( scale ) > 0 ) || ( scale == 0 ) )
			scale = 1
		endif
		
		strswitch( precision )
			case "S":
				Make /O/N=( npnts ) $wname = Nan
				break
			default:
				Make /D/O/N=( npnts ) $wname = Nan
		endswitch
		
		Wave wtemp = $wname
		
		for ( ncnt = 0 ; ncnt < npnts ; ncnt += 1 )
			wtemp[ ncnt ] = fDAQmx_ReadChan( boardName, chan, NM_NidaqDACMinVoltage, NM_NidaqDACMaxVoltage, -1 ) / scale
		endfor
		
		if ( NidaqErrorCheck( "NidaqPreScan" ) < 0 )
			return -1
		endif
		
	endfor
	
	ClampTelegraphAuto()
	
	return 0

End // NidaqPreScan

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqRead( board, chan, gain, npnts )
	Variable board, chan, gain, npnts
	
	Variable ncnt, avg, value
	String bname = NidaqBoardName( board )
	
	for ( ncnt = 0 ; ncnt < npnts ; ncnt += 1 )
		value = fDAQmx_ReadChan( bname, chan, NM_NidaqDACMinVoltage, NM_NidaqDACMaxVoltage, -1 )
		if ( numtype( value ) > 0 )
			return Nan
		endif
		avg += value
	endfor
	
	if ( NidaqErrorCheck( "NidaqPreScan" ) < 0 )
		return -1
	endif
	
	avg /= npnts
	
	SetNMvar( NMClampDF+"ClampReadValue", avg )
		
	return avg

End // NidaqRead

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqDacTimeScale( tscale )
	Variable tscale
	
	Variable icnt, wcnt, config, dt, board
	String wname, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	String dacList = NMStimBoardConfigActiveList( sdf, "DAC" )
	
	Variable nwaves = NumVarOrDefault( sdf+"NumStimWaves", 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( dacList ) ; icnt += 1 )
	
		config = str2num( StringFromList( icnt, dacList ) )
		board = WaveValOrDefault( bdf+"DACboard", config, 0 )
		
		for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
		
			wname = sdf + StimWaveName( "DAC", config, wcnt )
			
			if ( WaveExists( $wname ) == 1 )
				dt = tscale * NMStimSampleInterval( sdf, DAC=1 )
				Setscale /P x 0, dt, $wname
			endif
			
			//wname = sdf + StimWaveName( "pnDAC", config, wcnt )
			
			//if ( WaveExists( $wname ) == 1 )
				//dt = tscale * NMStimSampleInterval( sdf, DAC=1 )
				//Setscale /P x 0, dt, $wname
			//endif
			
		endfor
	
	endfor

End // NidaqDacTimeScale

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqMakeADCpre( numWaves )
	Variable numWaves

	Variable bcnt, wcnt, ccnt
	String wname, alist, xlist, oldlist = "", cdf = NMClampDF

	Wave /T preADClist = $( cdf+"preADClist" )
	
	String precision = StrVarOrDefault( cdf+"WavePrecision", "D" )
	
	for ( wcnt = 0 ; wcnt < DimSize( preADClist, 0 ) ; wcnt += 1 )
	for ( bcnt = 0 ; bcnt < DimSize( preADClist, 1 ) ; bcnt += 1 )
		
		alist = preADClist[wcnt][bcnt]
		
		if ( StringMatch( alist,oldlist ) == 0 )
		
			for ( ccnt = 0 ; ccnt < ItemsInList( alist ) ; ccnt += 1 )
			
				xlist = StringFromList( ccnt,alist )
				wname = StringFromList( 0,xlist,"," )
				
				strswitch( precision )
					case "S":
						Make /O/N=( numWaves ) $wname = Nan
						break
					default:
						Make /D/O/N=( numWaves ) $wname = Nan
				endswitch
				
			endfor
			
		endif
		
		oldlist = alist
		
	endfor
	endfor

End // NidaqMakeADCpre

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqMakeADC()
	
	Variable bcnt, wcnt, ccnt, samples
	String wname, alist, xlist, oldlist = "", cdf = NMClampDF, sdf = StimDF()

	Wave /T ADClist = $( cdf+"ADClist" )
	
	String precision = StrVarOrDefault( cdf+"WavePrecision", "D" )
	Variable dt = NumVarOrDefault( StimDF()+"SampleInterval", 1 )
	
	dt /= 1000 // convert to seconds
	
	for ( wcnt = 0 ; wcnt < DimSize( ADClist, 0 ) ; wcnt += 1 )
	for ( bcnt = 0 ; bcnt < DimSize( ADClist, 1 ) ; bcnt += 1 )
		
		alist = ADClist[wcnt][bcnt]
		
		samples = NMStimWavePoints( sdf, wcnt )
		
		if ( StringMatch( alist,oldlist ) == 0 )
		
			for ( ccnt = 0 ; ccnt < ItemsInList( alist ) ; ccnt += 1 )
			
				xlist = StringFromList( ccnt,alist )
				wname = StringFromList( 0,xlist,"," )
				
				strswitch( precision )
					case "S":
						Make /O/N=( samples ) $wname = Nan
						break
					default:
						Make /D/O/N=( samples ) $wname = Nan
				endswitch
				
				Setscale /P x 0, dt, $wname
				
			endfor
			
		endif
		
		oldlist = alist
		
	endfor
	endfor

End // NidaqMakeADC

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqUpdateLists()

	Variable bcnt, wcnt, config, chan, boardNum, tGainConfig, oldtgain, numChan, mode, foundPrescan
	String wname, wlist, wlist2, ylist, bname, modeStr
	
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	Variable numStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 0 )
	
	Variable tsamples = NM_ClampTelegraphSamplesToRead
	
	String tGainList = StrVarOrDefault( cdf+"TGainList", "" )
	
	String DACminmax = "," + num2str( NM_NidaqDACMinVoltage ) + "," + num2str( NM_NidaqDACMaxVoltage )
	String ADCtype = NM_NidaqADCChannelType
	
	if ( strlen( ADCtype ) > 0 )
		
		strswitch( ADCtype )
			case "Diff":
			case "RSE":
			case "NRSE":
			case "PDIFF":
				ADCtype = "/" + ADCtype
				break
			default:
				ADCtype = ""
		endswitch
		
	endif
	
	if ( WaveExists( $bdf+"ADCname" ) == 0 )
		return -1
	endif
	
	Wave /T ADCname = $bdf+"ADCname"
	Wave /T ADCmode = $bdf+"ADCmode"
	Wave ADCboard = $bdf+"ADCboard"
	Wave ADCchan = $bdf+"ADCchan"
	Wave ADCgain = $bdf+"ADCgain"
	Wave ADCtgain = $bdf+"ADCtgain"
	
	Wave /T DACname = $bdf+"DACname"
	Wave DACboard = $bdf+"DACboard"
	Wave DACchan = $bdf+"DACchan"
	
	Wave /T TTLname = $bdf+"TTLname"
	Wave TTLboard = $bdf+"TTLboard"
	Wave TTLchan = $bdf+"TTLchan"
	
	if ( strlen( tGainList ) > 0 )
		oldtgain = 1
	endif
	
	String bList = fDAQmx_DeviceNames()
	
	Variable numBoards = ItemsInList( bList )
	
	Make /T/O/N=( numStimWaves, numBoards ) $( cdf+"preADClist" ), $( cdf+"ADClist" ), $( cdf+"DAClist" ), $( cdf+"TTLlist" )
	
	Wave /T preADClist = $( cdf+"preADClist" )
	Wave /T ADClist = $( cdf+"ADClist" )
	Wave /T DAClist = $( cdf+"DAClist" )
	Wave /T TTLlist = $( cdf+"TTLlist" )
	
	preADClist = ""
	ADClist = ""
	DAClist = ""
	TTLlist = ""
	
	for ( wcnt = 0 ; wcnt < numStimWaves ; wcnt += 1 ) // loop through waves
	for ( bcnt = 0 ; bcnt < numBoards ; bcnt += 1 ) // loop through boards

		wlist = ""
		bname = StringFromList( bcnt, bList )
		numChan = fDAQmx_DIO_PortWidth( bname, NM_NidaqDIOPort )
		
		if ( NM_NidaqDIOPort < fDAQmx_NumDIOPorts(bname) ) // DIO port number is OK
		
			for ( config = 0 ; config < numpnts( TTLname ) ; config += 1 )
				
				boardNum = TTLboard[config]
				boardNum = NidaqBoardNumCheck( boardNum )
	
				if ( ( bcnt == boardNum - 1 ) && ( strlen( TTLname[config] ) > 0 ) )
				
					chan = TTLchan[config]
					
					if ( ( numtype( chan ) > 0 ) || ( chan < 0 ) || ( chan >= numChan ) )
						return ClampError( 1, "Config " + num2istr( config ) + " TTL channel is out of range: " + num2istr( chan ) )
					endif
						
					ylist = "," + num2istr( chan )
					
					wname = sdf + StimWaveName( "TTL", config, wcnt )
					
					WaveStats /Q $wName
			
					if ( ( V_max > 0 ) && ( V_max != 1 ) )
						return ClampError( 1, "Config " + num2istr( config ) + " TTL waveform should have values 0 or 1, but found a max value of " + num2str( V_max ) + " volts" )
					endif
				
					wlist = AddListItem( wname+ylist, wlist, ";", inf )
					
				endif
				
			endfor
			
			TTLlist[wcnt][bcnt] = wlist
		
		endif
		
	endfor
	endfor
	
	for ( wcnt = 0 ; wcnt < numStimWaves ; wcnt += 1 ) // loop through waves
	for ( bcnt = 0 ; bcnt < numBoards ; bcnt += 1 ) // loop through boards

		wlist = ""
		bname = StringFromList( bcnt, bList )
		numChan = fDAQmx_NumAnalogOutputs( bname )
		
		for ( config = 0 ; config < numpnts( DACname ) ; config += 1 )
			
			boardNum = DACboard[config]
			boardNum = NidaqBoardNumCheck( boardNum )

			if ( ( bcnt == boardNum - 1 ) && ( strlen( DACname[config] ) > 0 ) )
			
				chan = DACchan[config]
				
				if ( ( numtype( chan ) > 0 ) || ( chan < 0 ) || ( chan >= numChan ) )
					return ClampError( 1, "Config " + num2istr( config ) + " DAC channel is out of range: " + num2istr( chan ) )
				endif
					
				ylist = "," + num2istr( chan ) + DACminmax
				wname = sdf + StimWaveName( "DAC", config, wcnt )
				wlist = AddListItem( wname+ylist, wlist, ";", inf )
				
			endif
			
		endfor
		
		DAClist[wcnt][bcnt] = wlist
		
	endfor
	endfor
	
	for ( wcnt = 0 ; wcnt < numStimWaves ; wcnt += 1 ) // loop through waves
	for ( bcnt = 0 ; bcnt < numBoards ; bcnt += 1 ) // loop through boards
		
		wlist = ""
		wlist2 = ""
		bname = StringFromList( bcnt, bList )
		numChan = fDAQmx_NumAnalogInputs( bname )
		
		for ( config = 0 ; config < numpnts( ADCname ) ; config += 1 )
		
			boardNum = ADCboard[config]
			boardNum = NidaqBoardNumCheck( boardNum )
			modeStr = ADCmode[config]
			
			if ( ( bcnt == boardNum - 1 ) && ( strlen( ADCname[config] ) > 0 ) )
			
				if ( NMStimADCmodeNormal( modeStr ) == 1 )
			
					chan = ADCchan[config]
					
					if ( ( numtype( chan ) > 0 ) || ( chan < 0 ) || ( chan >= numChan ) )
						return ClampError( 1, "Config " + num2istr( config ) + " ADC channel is out of range: " + num2istr( chan ) )
					endif
				
					ylist = "," + num2istr( chan ) + ADCtype
					ylist += "," + num2str( ADCgain[config] )
					ylist += "," + num2istr( config )
					
					//wname = cdf + "ADC" + num2istr( config )
					wname = cdf + StimWaveName( "ADC", config, wcnt )
					wlist = AddListItem( wname+ylist, wlist, ";", inf )
					
					//if ( ( oldtgain == 1 ) && ( numtype( ADCtgain[config] ) == 0 ) )
						
						//ylist = "," + num2istr( ADCtgain[config] ) // channel to read
						//ylist += "," + num2istr( 1 )
						//ylist += "," + num2istr( 1 ) // 1 sample
						//ylist += "," + num2istr( -1 ) // no config number
						
						//wname = "CT_TGain" + num2istr( config )
						//wlist2 = AddListItem( wname+ylist, wlist2, ";", inf )
						
						//tgain = 1
						
					//endif
				
				elseif ( strsearch( modeStr, "PreSamp=", 0, 2 ) >= 0 ) // pre-sample
				
					mode = str2num( modeStr[8, inf] )
			
					ylist = "," + num2istr( ADCchan[config] ) + ADCtype
					ylist += "," + num2str( ADCgain[config] )
					ylist += "," + num2str( mode )
					ylist += "," + num2istr( config )
					
					wname = "CT_" + ADCname[config]
					wlist2 = AddListItem( wname+ylist, wlist2, ";", inf )
					
					foundPrescan = 1
				
				elseif ( strsearch( modeStr, "TGain=", 0, 2 ) >= 0 ) // telegraph gain
				
					//mode = ( -1 * ADCmode[config] - 100 )
				
					ylist = "," + num2istr( ADCchan[config] ) + ADCtype
					ylist += "," + num2istr( 1 )
					ylist += "," + num2istr( tsamples )
					ylist += "," + num2istr( -1 ) // no config number
					
					wname = "CT_TGain" + num2istr( ClampTGainChan( modeStr ) )
					wlist2 = AddListItem( wname+ylist, wlist2, ";", inf )
					
					tGainConfig = 1
					
				elseif ( StringMatch( modeStr[0,0], "T" ) == 1 ) // Telegraphs
				
					ylist = "," + num2istr( ADCchan[config] ) + ADCtype
					ylist += "," + num2istr( 1 )
					ylist += "," + num2istr( tsamples )
					ylist += "," + num2istr( -1 ) // no config number
				
					wname = "CT_" + ADCname[config]
					wlist2 = AddListItem( wname+ylist, wlist2, ";", inf )
				
				endif
				
			endif
			
		endfor
		
		ADClist[wcnt][bcnt] = wlist
		preADClist[wcnt][bcnt] = wlist2
		
	endfor
	endfor
	
	SetNMvar( cdf+"TGainConfig", tGainConfig )
	
	if ( foundPrescan == 1 )
		Print "Alert: NIDAQ presamples now occur once before main acquisition loop in epic precise mode."
	endif
	
	if ( NidaqErrorCheck( "NidaqUpdateLists" ) < 0 )
		return -1
	endif

End // NidaqUpdateLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqUpdateListsPN()

	Variable bcnt, wcnt, wcnt2, icnt, jcnt, chan
	String alist, dlist, tlist, ilist, ilist2, wname, PNwname, df, cdf = NMClampDF, sdf = StimDF()
	
	Variable pn = 0 // ClampPN()
	
	Variable PNconfig = NaN // ClampPN_DACconfig()
	
	if ( pn == 0 )
		return 0 // P / N subtraction is not on
	endif

	Wave /T ADClist = $( cdf+"ADClist" )
	Wave /T DAClist = $( cdf+"DAClist" )
	Wave /T TTLlist = $( cdf+"TTLlist" )
	
	Variable numStimWaves = DimSize( DAClist, 0 )
	Variable nwaves = numStimWaves + numStimWaves * abs( pn )
	Variable numBoards = DimSize( DAClist, 1 )
	
	Make /T/O/N=( nwaves, numBoards ) $( cdf+"ADClistPN" ), $( cdf+"DAClistPN" ), $( cdf+"TTLlistPN" )
	
	Wave /T ADClistPN = $( cdf+"ADClistPN" )
	Wave /T DAClistPN = $( cdf+"DAClistPN" )
	Wave /T TTLlistPN = $( cdf+"TTLlistPN" )
	
	for ( wcnt = 0 ; wcnt < DimSize( DAClist, 0 ) ; wcnt += 1 )
	for ( bcnt = 0 ; bcnt < DimSize( DAClist, 1 ) ; bcnt += 1 )
	
		alist = ADClist[wcnt][bcnt]
		dlist = DAClist[wcnt][bcnt]
		tlist = TTLlist[wcnt][bcnt]
		
		PNwname = "DAC_" + num2istr( PNconfig ) + "_" + num2istr( wcnt )
		
		for ( icnt = 0 ; icnt < ItemsInlist( dlist ) ; icnt += 1 )
		
			ilist = StringFromList( icnt, dlist )
			wname = StringFromList( 0, ilist, "," )
			chan = str2num(StringFromList( 1, ilist, "," ) )
			
			df = GetPathName( wname, 1 )
			wname = GetPathName( wname, 0 )
			
			if ( StringMatch( wname, PNwname ) == 1 )
			
				PNwname = "pn" + PNwname
			
				if ( WaveExists( $sdf+PNwname ) == 0 )
					return ClampError( 1, "NidaqUpdateListsPN Error: P / N waves do not exist" )
				endif
				
				ilist2 = sdf+PNwname + "," + num2istr(chan) + ";"
				
				for ( jcnt = 0 ; jcnt < abs( pn ) ; jcnt += 1 )
				
					if ( wcnt2 >= nwaves )
						return ClampError( 1, "NidaqUpdateListsPN Error: index out of range" )
					endif
					
					ADClistPN[wcnt2][bcnt] = alist
					DAClistPN[wcnt2][bcnt] = ilist2
					TTLlistPN[wcnt2][bcnt] = tlist
					
					wcnt2 += 1
					
				endfor
				
				break
				
			endif
			
		endfor
		
		if ( wcnt2 >= nwaves )
			return ClampError( 1, "NidaqUpdateListsPN Error: index out of range" )
		endif
		
		ADClistPN[wcnt2][bcnt] = alist
		DAClistPN[wcnt2][bcnt] = dlist
		TTLlistPN[wcnt2][bcnt] = tlist
		
		wcnt2 += 1
				
	endfor
	endfor

End // NidaqUpdateListsNP

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NidaqScanList( aList )
	String aList
	
	Variable icnt
	String item, oList = ""
	
	for ( icnt = 0 ; icnt < ItemsInList( aList ) ; icnt += 1 )
		item = StringFromList( icnt, aList )
		item = StringFromList( 0, item, "," ) + ", " + StringFromList( 1, item, "," )
		oList = AddListItem( item, oList, ";", inf )
	endfor
	
	return oList

End // NidaqScanList
	
//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqStartCounter( BoardName, Counter, WaveLength, InterStimTime ) // General Purpose Counter
	String BoardName
	Variable Counter
	Variable WaveLength, InterStimTime // msec
	
	if ( NMProgressCancel() == 1 )
		return 0
	endif
	
	if ( Counter >= fDAQmx_NumCounters( BoardName ) )
		return -1
	endif
	
	fDAQmx_CTR_Finished( BoardName, Counter )

	DAQmx_CTR_OutputPulse /DEV=( BoardName ) /TBAS="" /SEC={( WaveLength/1000 ), ( InterStimTime/1000 )} /NPLS=0 Counter
	
	if ( NidaqErrorCheck( "NidaqStartCounter" ) < 0 )
		return -1
	endif
	
	return 0
	
End // NidaqStartCounter

//****************************************************************
//****************************************************************
//****************************************************************

Function NidaqWait( BoardName, counter1, counter2, t ) // wait t msec using General Purpose Counters
	String BoardName
	Variable counter1
	Variable counter2
	Variable t // time in msec
	
	Variable count
	Variable tw = 0.005 / 1000 // seconds
	Variable cmax = t / ( tw * 2 * 1000 )
	
	String source = "/" + BoardName + "/Ctr" + num2istr( counter1 ) + "InternalOutput"
	
	if ( ( NMProgressCancel() == 1 ) || ( t <= 0 ) )
		return 0
	endif
	
	if ( Counter1 >= fDAQmx_NumCounters( BoardName ) )
		return -1
	endif
	
	if ( Counter2 >= fDAQmx_NumCounters( BoardName ) )
		return -1
	endif

	DAQmx_CTR_OutputPulse /DEV=BoardName /SEC={tw, tw} /NPLS=0 counter1
	DAQmx_CTR_CountEdges /DEV=BoardName /SRC=source counter2
	
	if ( NidaqErrorCheck( "NidaqWait" ) < 0 )
		return -1
	endif
	
	do
	
		if ( NMProgressCancel() == 1 )
			break
		endif
		
	while ( fDAQmx_CTR_ReadCounter( BoardName, counter2 ) < cmax )
	
	fDAQmx_CTR_Finished( BoardName, counter1 )
	fDAQmx_CTR_Finished( BoardName, counter2 )
	
	if ( NidaqErrorCheck( "NidaqWait" ) < 0 )
		return -1
	endif

	return 0
	
End // NidaqWait

//****************************************************************
//****************************************************************
//****************************************************************

Function NIDAQAcqContinuous()
	
	Variable nwaves, wcnt, bcnt, ccnt, icnt, onewave, start, chan, config, scale, tgainv
	Variable fifosize, chunks2copy, refnum, numFIFOchan
	Variable tgainChan, tscale
	
	String trig = "", driver = "", lastOUT = "", lastADC = "", extTrig = NidaqExtTrigger()
	String itemstr, instr, modeStr, chanList = ""
	String bname, dname, alist = "", olist = "", xlist = "", wlist = "", bList = fDAQmx_DeviceNames()
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	Variable /G V_DAQmx_DIO_TaskNumber = -1

	Variable WaveLength = NumVarOrDefault( cdf+"WaveLength", 0 )
	Variable NumStimWaves = NumVarOrDefault( cdf+"NumStimWaves", 0 )
	Variable NumStimReps = NumVarOrDefault( cdf+"NumStimReps", 0 )
	
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 1 )
	Variable acqMode = NumVarOrDefault( sdf+"AcqMode", -1 )
	Variable tGainConfig = NumVarOrDefault( cdf+"TGainConfig", 0 )
	
	Variable stats = NMStimStatsOn()
	Variable spike = NMStimSpikeOn()
	
	String chartPanel = "NMFIFOpanel"
	
	if ( ( acqMode != 1 ) && ( acqMode != 4 ) )
		return ClampError( 1, "NIDAQ continuous acquisition error" )
	endif
	
	if ( WaveExists( $bdf+"ADCscale" ) == 0 )
		return ClampError( 1, "NIDAQ continuous acquisition error" )
	endif
	
	Wave ADCscale = $bdf+"ADCscale"
	Wave ADCchan = $bdf+"ADCchan"
	Wave ADCtgain = $bdf+"ADCtgain"
	Wave /T ADCmode = $bdf+"ADCmode"
	
	Wave /T DAClist = $cdf+"DAClist"
	Wave /T TTLlist = $cdf+"TTLlist"
	Wave /T ADClist = $cdf+"ADClist"
	Wave /T preADClist = $cdf+"preADClist"
	
	nwaves = NumStimWaves * NumStimReps // total number of waves
	
	for ( bcnt = 0 ; bcnt < DimSize( ADClist, 1 ) ; bcnt += 1 )
	
		bname = StringFromList( bcnt, bList )
		ccnt = fDAQmx_NumCounters( bname )
		
		alist = ADClist[wcnt][bcnt]
		olist = DAClist[wcnt][bcnt]
		
		if ( ItemsInList( alist ) > 0 )
			lastADC = bname
			if ( ccnt > 1 )
				driver = bname
			endif
		endif

		if ( ItemsInList( olist ) > 0 )
			lastOUT = bname
			if ( ccnt > 1 )
				driver = bname
			endif
		endif
				
	endfor
	
	if ( ( strlen( lastADC ) == 0 ) || ( strlen( driver ) == 0 ) )
		return ClampError( 1, "NIDAQ board config error" )
	endif
	
	if ( DimSize( ADClist, 0 ) == 1 )
		onewave = 1
	endif
	
	for ( bcnt = 0 ; bcnt < DimSize( preADClist, 1 ) ; bcnt += 1 )
			
		alist = preADClist[0][bcnt] // driver ADC
		bname = StringFromList( bcnt, bList )
		
		if ( ( ItemsInList( alist ) > 0 ) && ( NidaqPreScan( bname, alist ) < 0 ) )
			return -1
		endif
	
	endfor
	
	if ( tGainConfig )
		ClampTGainScaleValue( bdf )
	endif
	
	chunks2copy = WaveLength / SampleInterval
	fifosize = 1.5 * chunks2copy
	
	fifosize = max( 5000, fifosize )
	
	SetNMvar( cdf+"FIFOcounter", 0 )
	
	if ( ( stats == 1 ) || ( spike == 1 ) )
		SetNMvar( cdf+"FIFOdisplaymode", 0 )
	else
		SetNMvar( cdf+"FIFOdisplaymode", 1 )
	endif
	
	FIFOStatus /Q NMFIFO
	
	if ( V_FLag != 0 )
		KillFIFO NMFIFO
	endif
	
	NewFIFO NMFIFO
	
	for ( bcnt = 0 ; bcnt < DimSize( ADClist, 1 ) ; bcnt += 1 )
	
		bname = StringFromList( bcnt, bList )
		ccnt = fDAQmx_NumCounters( bname )
		
		alist = ADClist[wcnt][bcnt]
		
		for ( ccnt = 0 ; ccnt < ItemsInList( alist ) ; ccnt += 1 )
			
			xlist = StringFromList( ccnt,alist )
			config = str2num( StringFromList( 3,xlist,"," ) )
			
			modeStr = ADCmode[ config ]
			
			if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
					
				//if ( NM_MultiClampTelegraphWhile == 1 )
					//scale = NMMultiClampScaleCall( modeStr )
				//else
					scale = NMMultiClampADCNum( sdf, config, "scale" )
				//endif
				
			else
			
				scale = ADCscale[ config ]
				
			endif
			
			if ( ( numtype( scale ) > 0 ) || ( scale <= 0 ) )
				scale = 1
			endif
			
			//Note $wname, "Scale Factor:" + num2str( scale ) ?????
					
			NewFIFOChan /D NMFIFO, $( "chan"+num2istr( ccnt ) ) 0,( 1/scale ),-1000,1000,""
			numFIFOchan += 1
			
		endfor
		
	endfor
	
	NIDAQ_FIFO_Chart_Update()
	
	PathInfo ClampSaveDataPath
	
	if ( V_flag == 0 )
		ClampPathsCheck()
	endif
	
	PathInfo ClampSaveDataPath
	
	if ( V_flag == 0 )
		return ClampError( 1, "NIDAQ continuous acquisition error: cannot create external data path." )
	endif
					
	Open /P=ClampSaveDataPath refnum as "NMfifo_backup"
	
	CtrlFIFO NMFIFO, deltaT=( SampleInterval/1000 ), size=fifosize, file=refnum
	
	NMHistory( "NIDAQmx continuous acquisition: data backed up in file " + S_path + "NMfifo_backup" )
	
	for ( bcnt = 0 ; bcnt < DimSize( TTLlist, 1 ) ; bcnt += 1 )
			
		bname = StringFromList( bcnt, bList )
		olist = TTLlist[0][bcnt]
		
		if ( ItemsInList( olist ) > 0 )
		
			if ( V_DAQmx_DIO_TaskNumber >= 0 )
				fDAQmx_DIO_finished( bname, V_DAQmx_DIO_TaskNumber )
			endif
			
			trig = "/" + driver + "/ai/sampleclock"
			
			wlist = ""
			xlist = ""
			
			for ( icnt = 0 ; icnt < ItemsInList( olist, ";" ) ; icnt += 1 )
				itemstr = StringFromList( 0, StringFromList( icnt, olist, ";" ), "," )
				wlist = AddListItem( itemstr, wlist, ",", inf )
				itemstr = StringFromList( 1, StringFromList( icnt, olist, ";" ), "," )
				itemstr = "/" + bname + "/port" + num2istr( NM_NidaqDIOPort ) + "/line" + itemstr
				xlist = AddListItem( itemstr, xlist, ",", inf )
			endfor
			
			icnt = strlen( wlist ) - 1
			wlist[ icnt, icnt ] = ""
			
			icnt = strlen( xlist ) - 1
			xlist[ icnt, icnt ] = ""
			
			Execute "DAQmx_DIO_Config /Dev=\"" + bname + "\" /LGRP=1 /RPTC=1 /DIR=1 /CLK={\"" + trig + "\", 1} /WAVE={" + wlist + "} \"" + xlist + "\""
			
		endif
		
	endfor
			
	if ( NidaqErrorCheck( "NIDAQAcqContinuous" ) < 0 )
		return -1
	endif
	
	for ( bcnt = 0 ; bcnt < DimSize( DAClist, 1 ) ; bcnt += 1 )
			
		bname = StringFromList( bcnt, bList )
		olist = DAClist[0][bcnt]
		
		if ( ItemsInList( olist ) > 0 )
		
			switch( acqMode )
			
				case 1: // continuous
		
					if ( StringMatch( bname, lastOUT ) == 1 )
						start = 1
						DAQmx_WaveformGen /DEV=bname /STRT=0 olist
					else
						trig = "/" + lastOUT + "/ao/starttrigger"
						DAQmx_WaveformGen /DEV=bname /TRIG={trig} olist
					endif
					
					break
					
				case 4: // continuous triggered
					start = 1
					DAQmx_WaveformGen /DEV=bname /NPRD=1 /TRIG={extTrig} olist
					break
					
				default:
					return -1
			
			endswitch
			
		endif
		
	endfor
	
	if ( NidaqErrorCheck( "NIDAQAcqContinuous" ) < 0 )
		return -1
	endif
	
	SetNMvar( cdf+"Background", 0 )
	
	SetBackground NIDAQ_FIFO_Display()
	CtrlBackground period=( 1 ), start
	
	CtrlFIFO NMFIFO, start
	
	for ( bcnt = 0 ; bcnt < DimSize( ADClist, 1 ) ; bcnt += 1 )
			
		bname = StringFromList( bcnt, bList )
		alist = ADClist[0][bcnt]
		
		if ( ItemsInList( alist ) > 0 )
		
			chanList = ""
		
			for ( ccnt = 0 ; ccnt < ItemsInList( alist ) ; ccnt += 1 )
				xlist = StringFromList( ccnt,alist )
				chan = str2num( StringFromList( 1,xlist,"," ) )
				chanList = AddListItem( num2istr( chan ), chanList, ";", inf )
			endfor
			
			if ( ItemsInList( chanList ) != numFIFOchan )
				return -1
			endif
			
			switch( acqMode )
					
				case 1: // continuous

					if ( StringMatch( bname, lastADC ) == 1 ) // driver board
						if ( start == 1 )
							trig = "/" + lastOUT + "/ao/starttrigger"
							DAQmx_Scan /DEV=bname /TRIG={trig} FIFO="NMFIFO; " + chanList
						else
							start = 2
							DAQmx_Scan /DEV=bname /STRT=0 FIFO="NMFIFO; " + chanList
						endif
					else // slave boards
						if ( start == 1 )
							trig = "/" + lastOUT + "/ao/starttrigger"
							DAQmx_Scan /DEV=bname /TRIG={trig} FIFO="NMFIFO; " + chanList
						else
							trig = "/" + lastADC + "/ai/starttrigger"
							DAQmx_Scan /DEV=bname /TRIG={trig} FIFO="NMFIFO; " + chanList
						endif
					endif
					
					break
					
				case 4: // continuous triggered
				
					if ( StringMatch( bname, lastADC ) == 1 )
						if ( start == 1 )
							trig = "/" + lastOUT + "/ao/starttrigger"
							DAQmx_Scan /DEV=bname /TRIG={trig} FIFO="NMFIFO; " + chanList
						else
							DAQmx_Scan /DEV=bname /TRIG={extTrig} FIFO="NMFIFO; " + chanList
						endif
					else
						if ( start == 1 )
							trig = "/" + lastOUT + "/ao/starttrigger"
							DAQmx_Scan /DEV=bname /BKG /TRIG={trig} FIFO="NMFIFO; " + chanList
						else
							trig = "/" + lastADC + "/ai/starttrigger"
							DAQmx_Scan /DEV=bname /BKG /TRIG={trig} FIFO="NMFIFO; " + chanList
						endif
					endif
							
					break
					
			endswitch
			
		endif
	
	endfor
	
	if ( NidaqErrorCheck( "NIDAQAcqContinuous" ) < 0 )
		return -1
	endif
	
	if ( acqMode == 1 )
	
		switch( start )
			case 1:
				fDAQmx_WaveformStart( lastOUT, 0 )
				break
			case 2:
				fDAQmx_ScanStart( lastADC, 1 )
				break
		endswitch
	
	endif
	
	if ( NidaqErrorCheck( "NIDAQAcqContinuous" ) < 0 )
		return -1
	endif			
	
	return 0

End // NIDAQAcqContinuous

//****************************************************************
//****************************************************************
//****************************************************************

Function NIDAQAcqContinuous_Stop()

	String fname = "", cdf = NMClampDF
	
	Variable mode = NumVarOrDefault( cdf+"PRTmode", 0 )
	Variable saveWhen = NumVarOrDefault( cdf+"SaveWhen", 0 )
	
	SetNMvar( cdf+"Background", 1 ) // stop FIFO background task
	
	FIFOStatus /Q NMFIFO
	
	if ( V_FLag != 0 )
	
		if ( V_FIFORunning == 1 )
			CtrlFIFO NMFIFO, stop
		endif
		
		KillFIFO NMFIFO
		
	endif
	
	NidaqResetBoard( -1, 0 )
	fname = NIDAQ_FIFO_Read( "ClampSaveDataPath", "NMfifo_backup", "default" ) // open FIFO file and copy data to current NM data folder
	
	ClampAcquireFinish( mode, saveWhen, 0 )
	
	if ( strlen( fname ) == 0 )
		PathInfo ClampSaveDataPath
		ClampError( 1, "Failed to import data from FIFO file " + S_path + "NMfifo_backup. To obtain data, select from main menu: NeuroMatic > Clamp FIFO Import." )
	endif

End // NIDAQAcqContinuous_Stop

//****************************************************************
//****************************************************************
//****************************************************************

Function NIDAQ_FIFO_Display()
	
	Variable tstart, ccnt, tbgn, tend, nwaves, update = 1
	String cdf = NMClampDF, sdf = StimDF(), chartPanel = "NMFIFOpanel"
	String wname, dwname, gname
	
	Variable dmode = NumVarOrDefault( cdf+"FIFOdisplaymode", 1 )
	
	Variable mode = NumVarOrDefault( cdf+"PRTmode", 0 )
	Variable background = NumVarOrDefault( cdf+"Background", 1 )
	
	Variable NumStimWaves = NumVarOrDefault( cdf+"NumStimWaves", 0 )
	Variable NumStimReps = NumVarOrDefault( cdf+"NumStimReps", 0 )
	
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 1 )
	Variable WaveLength = NumVarOrDefault( cdf+"WaveLength", 0 )
	
	Variable chartonly = NumVarOrDefault( cdf+"Chartonly", 0 )
	
	Variable chunks2copy = WaveLength / SampleInterval
	
	if ( background > 0 )
		return 1
	endif
	
	if ( exists( cdf + "FIFOcounter" ) != 2 )
		return 2
	endif
	
	NVAR counter = $cdf + "FIFOcounter"
	
	nwaves = NumStimWaves * NumStimReps
	
	FIFOStatus /Q NMFIFO
	
	if ( V_FLag == 0 )
		return 2
	endif
	
	if ( ( WinType( chartPanel ) == 7 ) && ( chartonly == 1 ) )
		update = 0
	endif
	
	if ( ( floor( V_FIFOChunks / chunks2copy ) ) > counter )
	
		counter = floor( V_FIFOChunks / chunks2copy ) - 1
		
		if ( update == 1 )
	
			if ( dmode == 0 )
				tbgn = 0
			else
				tbgn = counter * WaveLength
			endif
			
			tend = tbgn + WaveLength
		
			for ( ccnt = 0 ; ccnt < V_FIFOnchans ; ccnt += 1 )
			
				dwname = ChanDisplayWave( ccnt )
				gname = ChanGraphName( ccnt )
				
				Make /O/N=( chunks2copy*1.2 ) $dwname
				
				FIFO2Wave /S=1 NMFIFO, $( "chan" + num2istr( ccnt ) ), $dwname
				
				wname = GetWaveName( "default", ccnt, 0 )
				Duplicate /O $dwname $wname
				
				if ( dmode == 0 )
					tstart = 0
				else
					tstart = leftx( $wName ) * 1000
				endif
				
				
				Setscale /P x tstart, SampleInterval, "", $dwname, $wName
				
				SetAxis /W=$gname bottom tbgn, tend
				
			endfor
		
		endif
		
		ClampAcquireNext( mode, nwaves )
		
		counter += 1
		
		NMProgressCall( counter/nwaves, NMStrGet( "ProgressStr" ) )
		
		if ( counter == nwaves )
			NIDAQAcqContinuous_Stop()
			return 1
		endif
		
	endif
	
	if ( NMProgressCancel() == 1 )
		NIDAQAcqContinuous_Stop()
		return 1
	endif
	
	return 0
	
	//0:	background task executed normally
	//1:	background task wants to stop
	//2:	background task encountered error and wants to stop.
	
End // NIDAQ_FIFO_Display

//****************************************************************
//****************************************************************
//****************************************************************

Function NIDAQ_FIFO_Import()
	String filename

	filename = NIDAQ_FIFO_Read( "ClampSaveDataPath", "", "FIFO" )
	
	if ( strlen( filename ) > 0 )
		NMPrefixAdd( "FIFO" )
		NMHistory( filename + "...  data imported with wave prefix name \"FIFO\"" )
	endif

End // NIDAQ_FIFO_Import

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NIDAQ_FIFO_Read( pathstr, filename, WavePrefix )
	String pathstr
	String filename // enter empty quotes "" for open file dialog
	String wavePrefix // "default" for default wave prefix

	Variable refnum, chunks, totchunks, nchan, ccnt, tstart, nopath
	String wname, dwname, gname, sdf = StimDF()
	
	Variable SampleInterval = NumVarOrDefault( sdf+"SampleInterval", 1 )
	
	FIFOStatus /Q NMFIFO
	
	if ( V_FLag != 0 )
		KillFIFO NMFIFO
	endif
	
	NewFIFO NMFIFO
	
	PathInfo $pathstr
		
	if ( V_flag == 0 )
		return ""
	endif
	
	if ( strlen( filename ) == 0 )
	
		Open /R/D/P=$pathstr /T="????" refnum
		
		filename = S_filename
		
		if ( strlen( filename ) == 0 )
			return ""
		endif
		
		Open /Z/R refnum as filename
		
	else
	
		Open /Z/R/P=$pathstr refnum as filename
		
	endif
	
	if ( V_flag != 0 )
		return ""
	endif
	
	CtrlFIFO NMFIFO, rfile=refnum
	
	FIFOStatus /Q NMFIFO
	
	if ( V_FLag == 0 )
		return ""
	endif
	
	chunks = V_FIFOChunks
	nchan = V_FIFOnchans
	totchunks = Numberbykey( "DISKTOT", S_Info )
	
	for ( ccnt = 0 ; ccnt < nchan ; ccnt += 1 )
	
		wname = GetWaveName( wavePrefix, ccnt, 0 )
		dwname = ChanDisplayWave( ccnt )
		gname = ChanGraphName( ccnt )
	
		Make /O/N=( totchunks ) $wname
		
		//print wname, totchunks
	
		FIFO2Wave /S=1 NMFIFO, $( "chan" + num2istr( ccnt ) ), $wname
	
		Duplicate /O $wname, $dwname
		
		tstart = leftx( $wName ) * 1000
		Setscale /P x tstart, SampleInterval, "", $dwname, $wName
		SetAxis /A/W=$gname bottom 
	
	endfor
	
	KillFIFO NMFIFO
	
	return filename

End // NIDAQ_FIFO_Read

//****************************************************************
//****************************************************************
//****************************************************************

Function NIDAQ_FIFO_Chart_Call()

	String chartPanel = "NMFIFOpanel", cdf = NMClampDF
	
	Variable chan = NumVarOrDefault( cdf+"ChartChan", 0 )
	Variable offset = NumVarOrDefault( cdf+"ChartOffset", 0 )
	Variable gain = NumVarOrDefault( cdf+"ChartGain", 1 )
	Variable ppstrip = NumVarOrDefault( cdf+"ChartPPstrip", 100 )
	Variable line = NumVarOrDefault( cdf+"ChartLine", 1 )
	Variable update = NumVarOrDefault( cdf+"ChartUpdate", 1 )
	Variable scale = NumVarOrDefault( cdf+"ChartScale", 1.3 )
	Variable only = NumVarOrDefault( cdf+"Chartonly", 0 )
	
	Prompt chan, "input channel ( 0 for first channel )"
	Prompt offset, "vertical offset"
	Prompt gain, "vertical gain"
	Prompt ppstrip, "points per vertical strip ( > 0 )"
	Prompt line, "line style ( 0 ) dots ( 1 ) lines ( 2 ) sticks"
	Prompt update, "update ( 1 ) fast ( 2 ) status ( 3 ) status pens"
	Prompt scale, "chart scale factor"
	Prompt only, "display only chart ( 0 ) no ( 1 ) yes"
	
	DoPrompt "NIDAQ FIFO Chart Display", chan, offset, gain, ppstrip, line, update, scale, only
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMvar( cdf+"ChartChan", chan )
	SetNMvar( cdf+"ChartOffset", offset )
	SetNMvar( cdf+"ChartGain", gain )
	SetNMvar( cdf+"ChartPPstrip", ppstrip )
	SetNMvar( cdf+"ChartLine", line )
	SetNMvar( cdf+"ChartUpdate", update )
	SetNMvar( cdf+"ChartScale", scale )
	SetNMvar( cdf+"ChartOnly", only )
	
	NIDAQ_FIFO_Chart()
	NIDAQ_FIFO_Chart_Update()

End // NIDAQ_FIFO_Chart_Call

//****************************************************************
//****************************************************************
//****************************************************************

Function NIDAQ_FIFO_Chart()

	Variable width, height
	String chartPanel = "NMFIFOpanel", cdf = NMClampDF
	
	Variable scale = NumVarOrDefault( cdf+"ChartScale", 1.3 )
	
	if ( WinType( chartPanel ) == 7 )
		DoWindow /F $chartPanel
		return 0
	endif
	
	NewPanel /K=1/N=$chartPanel as "NIDAQ FIFO Chart"
	
	NMWinCascade( chartPanel )
	
	GetWindow $chartPanel wsize
	
	width = abs( V_right - V_left ) * scale
	height = abs( V_bottom - V_top ) * scale
	
	Chart NMFIFOchart, fifo=NMFIFO, size={width,height}
	
	return 0

End // NIDAQ_FIFO_Chart

//****************************************************************
//****************************************************************
//****************************************************************

Function NIDAQ_FIFO_Chart_Update()
	
	Variable width, height
	String chartPanel = "NMFIFOpanel", cdf = NMClampDF
	
	Variable chan = NumVarOrDefault( cdf+"ChartChan", 0 )
	Variable offset = NumVarOrDefault( cdf+"ChartOffset", 0 )
	Variable gain = NumVarOrDefault( cdf+"ChartGain", 1 )
	Variable ppstrip = NumVarOrDefault( cdf+"ChartPPstrip", 100 )
	Variable line = NumVarOrDefault( cdf+"ChartLine", 1 )
	Variable update = NumVarOrDefault( cdf+"ChartUpdate", 1 )
	Variable scale = NumVarOrDefault( cdf+"ChartScale", 1.3 )
	
	if ( WinType( chartPanel ) != 7 )
		return -1
	endif
	
	FIFOstatus /Q NMFIFO
	
	if ( chan >= V_FIFOnchans )
		chan = 0
	endif
	
	DoWindow /F $chartPanel
	
	GetWindow $chartPanel wsize
	
	width = abs( V_right - V_left ) * scale
	height = abs( V_bottom - V_top ) * scale
	
	Chart NMFIFOchart, fifo=NMFIFO, size={width,height}, uMode = update, ppStrip=ppstrip
	
	if ( chan < V_FIFOnchans )
		Chart NMFIFOchart, chans={chan}, gain( chan )=gain, offset( chan )=offset, lineMode( chan )=line
	endif

End // NIDAQ_FIFO_Chart_Update

//****************************************************************
//****************************************************************
//****************************************************************

Function NIDAQ_DIO_TEST() // NOTE, this will not work with E-series boards, ONLY m-series!!!

	Make /B/U/O DIO_Outwave
	
	Setscale /P x 0, 0.0001, DIO_Outwave

	DAQmx_DIO_Config /Dev="dev1" /LGRP=1 /DIR=1 /CLK={"/dev1/ao/sampleclock", 1} /WAVE={DIO_Outwave} "/dev1/port0/line1"

End // NIDAQ_DIO_TEST

//****************************************************************
//****************************************************************
//****************************************************************

#endif



