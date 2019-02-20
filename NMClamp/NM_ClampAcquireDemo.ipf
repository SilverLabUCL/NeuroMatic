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

Static Constant GaussNoiseSTDV = 0 // ( 0 ) for no noise ( > 0 ) add noise to simulated data
Static Constant DACSUM = 1 // ( 0 ) none ( 1 ) compute sum of DAC and add to simulated data

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NMClampDemoBoardList
//	detect the presence of board(s) and create board name list
//	called by ClampConfigBoard()
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMClampDemoBoardList()
	
	Variable myBoardExists = 0
	
	String boardList = "" // list of possible board names
	String cdf = NMClampDF
	
	// code placed here to determine if acquisition board is available
	myBoardExists = 1 // set to 1 for now
	
	if ( myBoardExists == 1 )
		boardList = "Demo" // create the list of board names
	endif
	
	SetNMstr( cdf + "BoardList", boardList )

	return boardList

End // NMClampDemoBoardList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NMClampDemoConfig
//	this function should perform any necessary initializations of the board(s)
//	called by ClampAcquireManager()
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampDemoConfig()
	
	// code here for any initiation of board(s)

	return 0
	
End // NMClampDemoConfig

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NMClampDemoAcquire
//	the function that acquires the data
//	called by ClampAcquireManager()
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampDemoAcquire( mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) test timers
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime
	
	Variable nwaves = NumStimWaves * NumStimReps // total number of waves
	
	String sdf = StimDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable acqMode = NumVarOrDefault( sdf + "AcqMode", 0 )
	
	if ( ( acqMode == 1 ) || ( acqMode == 4 ) ) // continuous
		InterStimTime = 0
		InterRepTime = 0
	endif
	
	if ( ClampAcquireStart( mode, nwaves ) == -1 )
		return -1
	endif
	
	if ( NMClampDemoPrescan() == -1 )
		return -1
	endif
	
	switch( acqMode )
	
		case 1: // continuous acquisition
		case 4: // continuous acquisition, externally triggered
			NMClampDemoAcqContinuous( mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime )
			break
		
		case 0: // epic precise acquisition, timed by board
		case 2: // episodic acquisition, timed by Igor software
		case 3: // episodic acquisition, externally triggered
			NMClampDemoAcqEpisodic( mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime )
			break
			
		default:
			return ClampAcquireError( thisfxn + " Error", "acquisition mode not recognized: " + num2istr( acqMode ) )
			
	endswitch 
	
	return 0
	
End // NMClampDemoAcquire

//****************************************************************
//****************************************************************
//****************************************************************

Static Function NMClampDemoAcqEpisodic( mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) test timers
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime
	
	Variable nwaves = NumStimWaves * NumStimReps // total number of waves
	
	Variable rcnt, wcnt, config, config2, chan, chanCount, scale, tgainv
	Variable firstConfig
	String wname, wname2, modeStr, wList, instrument
	String gdf, cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	String thisfxn = GetRTStackInfo( 1 )
	
	String wPrefix = "CT_ADCTEMP"
	String wNameDAC = "DAC_temp"
	
	Variable acqMode = NumVarOrDefault( sdf + "AcqMode", 0 )
	
	Variable SampleInterval = NumVarOrDefault( sdf + "SampleInterval", 0 )
	Variable SamplesPerWave = WaveLength / SampleInterval
	
	String useExistingDF = StrVarOrDefault( cdf + "DemoUseExistingDF", "" ) // set this data folder path to use existing data waves for demo acquisition
	
	if ( !WaveExists( $bdf + "ADCname" ) )
		return -1
	endif
	
	Wave /T ADCname = $bdf + "ADCname"
	Wave ADCchan = $bdf + "ADCchan"
	Wave ADCscale = $bdf + "ADCscale"
	Wave ADCtgain = $bdf+"ADCtgain"
	Wave /T ADCmode = $bdf + "ADCmode"
	
	Wave /T DACname = $bdf + "DACname"
	Wave DACchan = $bdf + "DACchan"
	
	Wave /T TTLname = $bdf + "TTLname"
	Wave TTLchan = $bdf + "TTLchan"
	
	Variable tGainConfigExists = NumVarOrDefault( cdf + "TGainConfigExists", 0 )
	
	for ( rcnt = 0; rcnt < NumStimReps; rcnt += 1 ) // loop thru reps
	
		for ( wcnt = 0; wcnt < NumStimWaves; wcnt += 1 ) // loop thru waves
		
			firstConfig = 1
			
			for ( config = 0; config < numpnts( DACname ); config += 1 ) // handle DAC outputs
			
				if ( strlen( DACname[ config ] ) > 0 )
					
					wname = sdf + StimWaveName( "DAC", config, wcnt )
					
					if ( !WaveExists( $wname ) )
						return ClampAcquireError( thisfxn + " Error", "cannot locate DAC wave: " + wname )
					endif
					
					chan = DACchan[ config ] // board DAC channel
					
					Wave DAC = $wname
					
					if ( DACSUM )
						if ( firstConfig )
							Duplicate /O DAC $wNameDAC
						else
							Wave dtemp = $wNameDAC
							dtemp += DAC
						endif
						
					endif
					
					// send DAC wave to board DAC channel
					
				endif
				
			endfor
			
			for ( config = 0; config < numpnts( TTLname ); config += 1 ) // handle TTL outputs
			
				if ( strlen( TTLname[ config ] ) > 0 )
					
					wname = sdf + StimWaveName( "TTL", config, wcnt )
					
					if ( !WaveExists( $wname ) )
						return ClampAcquireError( thisfxn + " Error", "cannot locate TTL wave: " + wname )
					endif
					
					chan = TTLchan[ config ] // board TTL channel
					
					Wave TTL = $wname
					
					// send TTL wave to board TTL channel
					
				endif
				
			endfor
			
			// ACQUIRE DATA HERE
			// for now we create waves
			// if AcqMode = 3 ( episodic, externally triggered ) then acquisition should be triggered somehow
	
			for ( config = 0; config < numpnts( ADCname ); config += 1 )
			
				modeStr = ADCmode[ config ]
				chan = ADCchan[ config ]
			
				if ( ( strlen( ADCname[ config ] ) > 0 ) && ( NMStimADCmodeNormal( modeStr ) == 1 ) )
				
					wname = wPrefix + num2str( chan )
					
					Make /O/N=( SamplesPerWave ) $wname
					Setscale /P x 0, SampleInterval, $wname
					
					Wave wtemp = $wname
				
					if ( GaussNoiseSTDV > 0 )
						wtemp = gnoise( GaussNoiseSTDV )
					else
						wtemp = 0
					endif
					
					if ( DACSUM && WaveExists( $wNameDAC ) )
						Wave dtemp = $wNameDAC
						wtemp += dtemp
					endif
				
				endif
				
			endfor
			
			chanCount = 0
	
			for ( config = 0; config < numpnts( ADCname ); config += 1 ) // scale and save acquired data
			
				modeStr = ADCmode[ config ]
				chan = ADCchan[ config ]
			
				if ( ( strlen( ADCname[ config ] ) > 0 ) && ( NMStimADCmodeNormal( modeStr ) == 1 ) )
				
					wname = wPrefix + num2str( chan )
					
					if ( !WaveExists( $wname ) )
						return -1 // something went wrong with acquisition
					endif
					
					Wave wtemp = $wname
				
					gdf = ChanDF( chanCount )
					
					if ( NMMultiClampTelegraphMode( modeStr ) == 1 )
						scale = NMMultiClampADCNum( sdf, config, "scale" )
					else
						scale = ADCscale[ config ]
					endif
				
					config2 = ADCtgain[ config ]
					
					if ( ( tGainConfigExists == 1 ) && ( numtype( config2 ) == 0 ) )
						instrument = ClampTelegraphInstrument( ADCmode[ config2 ] )
						tgainv = ClampTGainValue( GetDataFolder( 1 ), ADCchan[ config ], CurrentNMWave() )
						scale = MyTelegraphGain( tgainv, scale, instrument )
					endif
					
					if ( ( numtype( scale ) == 0 ) || ( scale > 0 ) )
						wtemp /= scale
					else
						scale = 1
					endif
					
					if ( mode == 1 ) // record
						wname2 = GetWaveName( "default", chanCount, CurrentNMWave() ) // increment wave name sequence number
					else // preview
						wname2 = GetWaveName( "default", chanCount, 0 ) // overwrite first wave
					endif
					
					if ( ( strlen( useExistingDF ) > 0 ) && DataFolderExists( useExistingDF ) )
					
						wname = GetWaveName( "default", chanCount, CurrentNMWave() )
						
						if ( WaveExists( $useExistingDF+wname ) )
							Duplicate /O $useExistingDF+wname $wname2
						else
							Duplicate /O wtemp $wname2 // save data waves
							Note $wname2, "Scale Factor:" + num2str( scale )
						endif
						
					else
					
						Duplicate /O wtemp $wname2 // save data waves
						Note $wname2, "Scale Factor:" + num2str( scale )
						
					endif
	
					ChanWaveMake( chanCount, wname2, ChanDisplayWave( chanCount ), xWave = "" ) // make channel graph wave
					
					if ( NumVarOrDefault( gdf + "overlay", 0 ) > 0 )
						ChanOverlayUpdate( chanCount ) // channel graph overlay update
					endif
			
					if ( ( mode == 1 ) && ( saveWhen == 2 ) )
						ClampNMBAppend( wname2 ) // update waves in saved folder
					endif
					
					chanCount += 1
					
				endif
				
			endfor
			
			ClampAcquireNext( mode, nwaves )
			
			if ( ( rcnt == NumStimReps - 1 ) && ( wcnt == NumStimWaves - 1 ) )
				break // finished
			endif
			
			if ( NMProgressCancel() == 1 )
				break
			endif
			
			// inter-wave time delay
				
			if ( AcqMode == 0 ) // delay is timed by board somehow
				ClampWaitMSTimer( InterStimTime ) // use Igor timer for now
			elseif ( AcqMode == 2 ) // delay is timed by Igor
				ClampWaitMSTimer( InterStimTime )
			endif
			
			if ( NMProgressCancel() == 1 )
				break
			endif
	
		endfor
		
		if ( rcnt == NumStimReps - 1 )
			break // finished
		endif
		
		// inter-rep time delay
		
		if ( AcqMode == 0 ) // delay is timed by board somehow
			ClampWaitMSTimer( InterStimTime ) // but use Igor timer for now
		elseif ( AcqMode == 2 ) // delay is timed by Igor
			ClampWaitMSTimer( InterStimTime )
		endif
		
		if ( NMProgressCancel() == 1 )
			break
		endif
		
	endfor
	
	// kill temporary waves and variables
	
	wList = WaveList( wPrefix + "*", ";", "")
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		wname = StringFromList( wcnt, wList )
		KillWaves /Z $wname
	endfor
	
	ClampAcquireFinish( mode, savewhen, 1 )
	
	return 0
	
End // NMClampDemoAcqEpisodic

//****************************************************************
//****************************************************************
//****************************************************************

Static Function NMClampDemoAcqContinuous( mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) test timers
	Variable savewhen // ( 0 ) never ( 1 ) after ( 2 ) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime
	
	Variable nwaves = NumStimWaves * NumStimReps // total number of waves
	
	String sdf = StimDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable acqMode = NumVarOrDefault( sdf + "AcqMode", 0 )
	
	// not sure if this code needs to be different from episodic code
	// depends on board
	
End // NMClampDemoAcqContinuous

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NMClampDemoPrescan
//	loop thru ADC inputs and acquire channels that are
//	configured for pre-sampling, telegraph gain or and othe telegraphs
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampDemoPrescan() // pre-sample ADC inputs

	Variable config, chan, scale, numSamples, tGainConfigExists
	String modeStr, wname, name
	String thisfxn = GetRTStackInfo( 1 )

	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	if ( !WaveExists( $bdf + "ADCname" ) )
		return -1
	endif

	Wave /T ADCname = $bdf + "ADCname"
	Wave ADCchan = $bdf + "ADCchan"
	Wave ADCscale = $bdf + "ADCscale"
	Wave /T ADCmode = $bdf + "ADCmode"

	for ( config = 0 ; config < numpnts( ADCname ) ; config += 1 )
	
		name = ADCname[ config ]
		
		if ( strlen( name ) > 0 )
		
			chan = ADCchan[ config ]
			scale = ADCscale[ config ]
			modeStr = ADCmode[ config ]
			
			if ( NMStimADCmodeNormal( modeStr ) == 1 ) // normal acquisition
			
				// nothing to do
			
			elseif ( strsearch( modeStr, "PreSamp=", 0, 2 ) >= 0 ) // pre-sample acquisition
			
				numSamples = str2num( modeStr[ 8, inf ] )
				wname = "CT_" + name
			
				// acquire samples from ADC channel
				
				Make /O/N=( numSamples ) $wName = 0
				
				Wave wtemp = $wName
				
				if ( GaussNoiseSTDV > 0 )
					wtemp = gnoise( GaussNoiseSTDV )
				endif
				
				if ( ( numtype( scale ) == 0 ) && ( scale > 0 ) )
					wtemp /= scale
				endif
			
			elseif ( strsearch( modeStr, "TGain=", 0, 2 ) >= 0 ) // telegraph gain
			
				numSamples = NM_ClampTelegraphSamplesToRead
				wname = "CT_TGain" + num2istr( ClampTGainChan( modestr ) )
			
				// acquire samples from ADC channel
				
				Make /O/N=( numSamples ) $wName = 0
				
				Wave wtemp = $wName
				
				if ( GaussNoiseSTDV > 0 )
					wtemp = gnoise( GaussNoiseSTDV )
				endif
				
				if ( ( numtype( scale ) == 0 ) && ( scale > 0 ) )
					wtemp /= scale
				endif
				
				tGainConfigExists = 1
			
			elseif ( StringMatch( modeStr[0,0], "T" ) == 1 ) // other telegraphs
			
				numSamples = NM_ClampTelegraphSamplesToRead
				wname = "CT_" + name
			
				// acquire samples from ADC channel
				
				Make /O/N=( numSamples ) $wName = 0
				
				Wave wtemp = $wName
				
				if ( GaussNoiseSTDV > 0 )
					wtemp = gnoise( GaussNoiseSTDV )
				endif
				
				if ( ( numtype( scale ) == 0 ) && ( scale > 0 ) )
					wtemp /= scale
				endif
			
			endif
			
		endif
		
	endfor
	
	SetNMvar( cdf + "TGainConfigExists", tGainConfigExists ) // save the telegraph flag

	return 0

End // NMClampDemoPrescan

//****************************************************************
//****************************************************************
//****************************************************************
