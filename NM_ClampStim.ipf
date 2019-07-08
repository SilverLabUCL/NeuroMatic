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

StrConstant NMStimsDF = "root:NMStims:"
StrConstant NMStimPulseTable = "PG_StimTable"

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Directory Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStimsDF()

	if (DataFolderExists( NMStimsDF ) == 0)
		NewDataFolder $RemoveEnding( NMStimsDF, ":" )
	endif

End // CheckNMStimsDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimDF() // full-path name of current stim folder

	String cdf = NMPackageDF("Clamp")
	String sdf = NMStimsDF + StrVarOrDefault(cdf+"CurrentStim", "") + ":"
	
	if (DataFolderExists(sdf) == 1)
		return sdf
	endif

	return "" // error
	
End // StimDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckStimDF(sdf)
	String sdf
	
	if (strlen(sdf) == 0)
		return StimDF() // return current stim
	endif
	
	if (IsNMFolder(sdf, "NMStim") == 1)
		return LastPathColon(sdf, 1) // OK
	endif
	
	return "" // error
	
End // CheckStimDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimBoardDF(sdf) // subfolder where board configs are saved
	String sdf
	
	String bdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif

	return sdf + "BoardConfigs:"

End // NMStimBoardDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimList()

	return NMFolderList( NMStimsDF, "NMStim" )

End // StimList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimAcqModeList()

	return "episodic;epic precise;epic triggered;continuous;continuous triggered;"
	
End // NMStimAcqModeList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimAcqModeStr(acqModeNum)
	Variable acqModeNum
	
	switch(acqModeNum)
		case 0:
			return "episodic"
		case 1:
			return "continuous"
		case 2:
			return "epic precise"
		case 3:
			return "epic triggered"
		case 4:
			return "continuous triggered"
		default:
			return ""
	endswitch
	
End // NMStimAcqModeStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimSampleInterval( sdf [ DAC ] )
	String sdf // stim data folder path
	Variable DAC // ( 1 ) for specifying a different sample interval for DAC waveforms
	
	sdf = CheckStimDF( sdf )
	
	Variable intvl = NumVarOrDefault( sdf + "SampleInterval", NaN )

	if ( NMClampAllowUpSamplingDAC() && DAC )
		intvl = NumVarOrDefault( sdf + "SampleInterval_DAC", intvl )
	endif
	
	return ( floor( 1e6 * intvl ) / 1e6 )

End // NMStimSampleInterval

//****************************************************************
//****************************************************************
//****************************************************************

Function StimIntervalGet_DEPRECATED1(sdf, boardNum)
	String sdf // stim data folder path
	Variable boardNum // NOT USED
	
	sdf = CheckStimDF(sdf)
	
	return StimIntervalCheck(NumVarOrDefault(sdf+"SampleInterval", 1))
		
End // StimIntervalGet_DEPRECATED1

//****************************************************************
//****************************************************************
//****************************************************************

Function StimIntervalGet_DEPRECATED2(sdf, boardNum)
	String sdf // stim data folder path
	Variable boardNum
	
	Variable sampleInterval
	String varName
	
	sdf = CheckStimDF(sdf)
	
	sampleInterval = NumVarOrDefault(sdf+"SampleInterval", 1) // default driver value

	varName = sdf + "SampleInterval_" + num2istr(boardNum) // board-specific sample interval
	
	if (exists(varName) == 2)
		sampleInterval = NumVarOrDefault(varName, sampleInterval)
	endif
	
	return StimIntervalCheck(sampleInterval)
		
End // StimIntervalGet_DEPRECATED2

//****************************************************************
//****************************************************************
//****************************************************************

Function StimIntervalCheck( intvl )
	Variable intvl
	
	return ( floor( 1e6 * intvl ) / 1e6 )
	
End // StimIntervalCheck

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavesCheck(sdf, forceUpdate)
	String sdf // stim data folder
	Variable forceUpdate

	Variable icnt, jcnt, items, config, npnts, new, numWaves
	String stimName, io, wName, wPrefix, preFxnList, interFxnList
	String klist, plist, ulist, wList = ""
	
	Variable zeroDACLastPoints = NumVarOrDefault( NMClampDF + "ZeroDACLastPoints", 1 )
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	stimName = NMChild( sdf )
	
	numWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	
	plist = StimPrefixListAll(sdf)
	
	wList = NMFolderWaveList( sdf, "*_pulse", ";", "", 0 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		wName = StringFromList( icnt, wList )
		NMStimWavesPulseUpdate( sdf, wName )
	endfor
	
	for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
	
		wPrefix = StringFromList(icnt, plist)
		io = StimPrefix(wPrefix)
		config = StimConfigNum(wPrefix)
		
		wList = NMFolderWaveList(sdf, wPrefix + "*", ";", "",0)
		wList = RemoveFromList(wPrefix + "_pulse", wList)
		
		ulist = NMFolderWaveList(sdf, "u"+wPrefix + "*", ";", "",0) // unscaled waves for display
		
		if (ItemsInLIst(ulist) == 0)
			ulist = NMFolderWaveList(sdf, "My"+wPrefix + "*", ";", "",0) // try "My" waves
		endif
		
		if (forceUpdate || (ItemsInList(wList) < numWaves) || (ItemsInList(ulist) < numWaves))
			wList += StimWavesMake(sdf, io, config, NaN)
			new = 1
		endif
	
		items = ItemsInList( wList )
		
		if ( zeroDACLastPoints && ( items > 0 ) )
		
			jcnt = items - 1 // does this for last wave in list
			
			wName = StringFromList( jcnt, wList )
				
			if ( WaveExists( $sdf + wName ) )
			
				Wave wtemp = $sdf + wName
				
				npnts = numpnts( wtemp )
				
				wtemp[ npnts - 1 ] = 0 // make sure last 2 points are 0
				wtemp[ npnts - 2 ] = 0
			
			endif
		
		endif
	
	endfor
	
	if (new == 1)
	
		klist = NMFolderWaveList(sdf, "ITCoutWave*", ";", "",0)
		
		for (icnt = 0; icnt < ItemsInList(klist); icnt += 1)
			KillWaves /Z $StringFromList(icnt, klist)
		endfor
		
	endif
	
	preFxnList = StrVarOrDefault( sdf + "PreStimFxnList", "" )
	
	if ( WhichListItem( "RandomOrder", preFxnList ) >= 0 ) // move RandomOrder to InterStimFxnList
	
		interFxnList = StrVarOrDefault( sdf + "InterStimFxnList", "" )
		
		if ( WhichListItem( "RandomOrder", interFxnList ) < 0 )
			interFxnList = AddListItem( "RandomOrder", interFxnList, ";", inf )
			SetNMstr( sdf + "InterStimFxnList", interFxnList )
		endif
		
		preFxnList = RemoveFromList( "RandomOrder", preFxnList )
		
		SetNMstr( sdf + "PreStimFxnList", preFxnList )
		
		NMHistory( "Clamp Stim " + stimName + " : RandomOrder moved to " + NMQuotes( "during" ) + " acquisition macro list." )
	
	endif
	
	return wList

End // StimWavesCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimWavesPulseUpdate( sdf, wNameOld )
	String sdf
	String wNameOld
	
	Variable pcnt, TTL
	String paramList
	
	String wNameNew = "NM_PulseConvertTemp"
	
	if ( !WaveExists( $sdf+wNameOld ) )
		return 0
	endif
	
	if ( StringMatch( wNameOld[ 0, 3 ], "TTL_" ) )
		TTL = 1
	endif
	
	if ( WaveType( $sdf+wNameOld, 1 ) == 2 )
	
		if ( TTL )
		
			Wave /T wtemp = $sdf+wNameOld
	
			for ( pcnt = 0; pcnt < numpnts( wtemp ); pcnt += 1 )
			
				paramList = wtemp[ pcnt ]
				
				if ( strlen( paramList ) > 0 )
					paramList = ReplaceStringByKey( "pulse", wtemp[ pcnt ], "squareTTL", "=", ";" )
					wtemp[ pcnt ] = paramList
				endif
				
			endfor
		
		endif
	
		return 0
	
	endif
	
	if ( numpnts( $sdf+wNameOld ) > 0 )
		NMPulseConfigWaveUpdate( sdf, wNameOld, wNameNew, TTL=TTL )
	endif
	
	KillWaves /Z $sdf+wNameOld
	
	if ( WaveExists( $sdf+wNameOld ) )
		DoAlert 0, "NM Error : NMStimWavesPulseUpdate :  cannot kill old pulse wave"
		return -1
	endif
	
	if ( WaveExists( $sdf+wNameNew ) )
	
		Duplicate /O $sdf+wNameNew $sdf+wNameOld
	
		KillWaves /Z $sdf+wNameNew
		
	endif
	
	NMHistory( "Updated NM Stim pulse wave " + sdf + wNameOld )
	
End // NMStimWavesPulseUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWavesMake(sdf, io, config, xTTL)
	String sdf // stim data folder
	String io // "DAC" or "TTL"
	Variable config // config number
	Variable xTTL // not used anymore
	
	Variable wcnt, dt, scale, alert
	String pName, wPrefix, wName, wList = "", wList2, ioUnits
	String bdf = NMStimBoardDF(sdf)
	
	STRUCT NMParams nm
	STRUCT NMMakeStruct m
	
	NMParamsNull( nm )
	NMMakeStructNull( m )
	
	Variable numWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable wLength = NumVarOrDefault(sdf+"WaveLength", NMStimWaveLength)
	Variable pgOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	
	if (DataFolderExists(sdf) == 0)
		return ""
	endif
	
	if ((StringMatch(io, "DAC") == 0) && (StringMatch(io, "TTL") == 0))
		return ""
	endif
	
	if (WaveExists($bdf+io+"board") == 1) // new board configs
		
		Wave OUTboard = $bdf+io+"board"
		Wave OUTscale = $bdf+io+"scale"
		Wave /T OUTunits = $bdf+io+"units"
		
	elseif (WaveExists($sdf+io+"board") == 1) // old board configs
	
		Wave OUTboard = $sdf+io+"board"
		Wave OUTscale = $sdf+io+"scale"
		Wave /T OUTunits = $sdf+io+"units"
	
	else
	
		return ""
	
	endif
	
	if ( ( config < 0 ) || ( config >= numpnts( OUTscale ) ) || ( config >= numpnts( OUTboard ) ) || ( config >= numpnts( OUTunits ) ) )
		return ""
	endif
	
	scale = 1 / OUTscale[config]
	
	dt = NMStimSampleInterval( sdf, DAC = 1 )
	
	wPrefix = StimWaveName(io, config, -1)
	
	PulseWavesKill(sdf, wPrefix)
	PulseWavesKill(sdf, "u"+wPrefix)
	
	pName = PulseWaveName( sdf, wPrefix )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		wName = wPrefix + "_" + num2istr( wcnt )
		wList = AddListItem( wName, wList, ";", inf )
	endfor
	
	wList2 = wList
	
	if (pgOff == 1) // use "My" waves, such as MyDAC_0_0, MyDac_0_1, etc.
	
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		
			wName = StringFromList(wcnt, wList)
			
			if (WaveExists($sdf+"My"+wName) == 1)
			
				//if ((deltax($sdf+"My"+wName) != dt) && (alert == 0))
					//NMDoAlert("Error: encountered incorrect sample interval for wave: " + sdf + "My" + wName + " : " + num2str(deltax($sdf+"My"+wName)) + " , " + num2str(dt)
 					//alert = 1
					//continue
				//endif
			
				Duplicate /O $(sdf+"My"+wName) $(sdf+wName) // copy existing "My" wave
				
				Wave wtemp = $sdf+wName
				
				wtemp *= scale
				
				KillWaves /Z $sdf+"u"+wName
				
				wList2 = RemoveFromList( wName, wList2 )
				
				//print "Updated " + wName
	
			endif
			
		endfor
		
	endif
	
	nm.folder = sdf
	nm.wList = wList2
	m.xpnts = wLength / dt
	m.dx = dt
	m.overwrite = 1
	m.xLabel = NMXunits
	m.yLabel = "V" // OUTunits[ config ]
	m.value = 0
	
	NMPulseWavesMake2( pName, nm, m, scale = scale )
		
	for (wcnt = 0; wcnt < ItemsInList(wList2); wcnt += 1)
	
		wName = StringFromList(wcnt, wList2)
		
		if (WaveExists($sdf+wName) == 1) // create display wave
		
			Duplicate /O $(sdf+wName) $(sdf+"u"+wName)
			
			Wave wtemp = $sdf+"u"+wName
			
			wtemp /= scale // remove scaling
			
			if ( !StringMatch( "V", OUTunits[ config ] ) )
				NMNoteStrReplace( sdf+"u"+wName, "yLabel", OUTunits[ config ] )
			endif
		
		endif
		
	endfor
	
	//if ( StringMatch(io, "TTL") ) // check TTL scaling
	
		//for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
		
			//wName = StringFromList(wcnt, wList)
			
			//WaveStats /Q $sdf+wName
			
			//if ( ( V_max > 0 ) && ( V_max != 5 ) )
				
				//Wave wtemp = $sdf+wName
				
				//wtemp *= 5 / V_max // scale to 5 volts // NIDAQmx TTL should have values of 0 and 1
				
			//endif
			
		//endfor
		
	//endif
	
	Execute /Z "ITCkillWaves()"
	
	return wList

End // StimWavesMake

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StimTableCall(sdf, pName)
	String sdf // stim data folder
	String pName // pulse wave name or "All"
	
	Variable icnt
	String plist = StimPulseList(sdf)
	String prefix, tName
	
	Variable pgOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	
	String folderPrefix = NMFolderListName( "" )
	
	if (pgOff == 1)
		//NMDoAlert("Pulse Generator was turned off for this stimulus.")
		//return -1
	endif
	
	if (strlen(pName) == 0)
		
		switch(ItemsInList(plist))
		
			case 0:
			
				NMDoAlert("This folder has no stimulus configuration.")
				return -1
			
			case 1:
			
				pName = StringFromList(0, plist)
				break
			
			default:
		
				Prompt pName, "select stim pulse configuration:", popup plist
				DoPrompt "Stim Pulse Table", pName
				
				if (V_flag == 1)
					return 0 // cancel
				endif
				
		endswitch
	
	endif
	
	if (StringMatch(pName, "All") == 1)
	
		if (ItemsInList(plist) == 0)
			NMDoAlert("Found no stim pulse configurations.")
			return 0
		endif
	
		for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
			pName = StringFromList(icnt, plist)
			prefix = pName[0,0] + pName[4,4] + "_"
			tName = "CT_" + folderPrefix + "_" + pName
			StimTable(sdf, sdf+pName, sdf, prefix, tableName = tName )
		endfor

	else
	
		prefix = pName[0,0] + pName[4,4] + "_"
		tName = "CT_" + folderPrefix + "_" + pName
		StimTable(sdf, sdf+pName, sdf, prefix, tableName = tName )
		
	endif

End // StimTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTable(sdf, pName, df, prefix [ tableName ] )
	String sdf // stim data folder
	String pName // pulse wave name (full-path)
	String df // data folder where pulse waves are located
	String prefix // prefix of table waves
	String tableName
	
	String ioName = StimConfigStr(sdf, pName, "name")
		
	String title =  ioName + " : " + NMChild( pName )
	
	STRUCT Rect w
	
	if ( !WaveExists( $pname ) )
		return ""
	endif
	
	if ( ParamIsDefault( tableName ) || ( strlen( tableName ) == 0 ) )
		tableName = NMStimPulseTable
	endif
	
	DoWindow /K $tableName
	
	NMWinCascadeRect( w )
	
	Edit /K=1/N=$tableName/W=(w.left,w.top,w.right,w.bottom) $(pName) as title
	
	Execute /Z "ModifyTable title(Point)= " + NMQuotes( "Config" )
	Execute /Z "ModifyTable alignment=0"
	Execute /Z "ModifyTable width=400"
	Execute /Z "ModifyTable width( Point )=40"
	
	return tableName

End // StimTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigTable(sdf, io, wList, hook)
	String sdf // stim data folder path
	String io // "ADC", "DAC" or "TTL"
	String wList // wave name list ("") for all
	Variable hook // (0) no update (1) updateNM
	
	Variable icnt
	String wName, tName, title, bdf = NMStimBoardDF(sdf)
	
	String stim = NMChild( sdf )
	
	STRUCT Rect w
	
	tName = NMCheckStringName(io + "_" + stim)
	
	if (WinType(tName) == 2)
		DoWindow /F $tName
		return 0
	endif
	
	title = io + " Input Configs : " + stim
	
	if (ItemsInList(wList) == 0)
	
		wList = "name;units;board;chan;scale;"
		
		if (StringMatch(io, "ADC") == 1)
			wList = AddListItem("mode;gain;", wList, ";", inf)
		endif
		
	endif
	
	DoWindow /K $tName
	
	NMWinCascadeRect( w )
	
	Edit /N=$tName/W=(w.left,w.top,w.right,w.bottom)/K=1 as title[0,30]
	
	Execute "ModifyTable title(Point)= " + NMQuotes( "Config" )
	
	if (hook == 1)
		SetWindow $tName
	endif
	
	for (icnt = 0; icnt < ItemsInList(wList); icnt += 1)
	
		if (DataFolderExists(bdf) == 1)
			wName = bdf + io + StringFromList(icnt,wList)
		else
			wName = sdf + io + StringFromList(icnt,wList)
		endif
		
		if (WaveExists($wName) == 1)
			AppendToTable $wName
		endif
	
	endfor

End // NMStimBoardConfigTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Utility Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function IsStimFolder(dp, sname)
	String dp // path
	String sname // stim name
	
	return IsNMFolder(LastPathColon(dp, 1) + sname + ":", "NMStim")
	
End // IsStimFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimPrefixListAll(sdf)
	String sdf // stim data folder
	
	return StimPrefixList(sdf, "DAC") + StimPrefixList(sdf, "TTL")

End // StimPrefixListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimPrefixList(sdf, io)
	String sdf // stim data folder
	String io // "DAC" or "TTL"
	
	Variable icnt
	String wName, wList = "", bdf = NMStimBoardDF(sdf)
	
	if ((StringMatch(io, "DAC") == 0) && (StringMatch(io, "TTL") == 0))
		return ""
	endif
	
	wName = bdf + io + "name"
	
	if (WaveExists($wName) == 1)
	
		Wave /T name = $wName // new stim board config wave
		
		for (icnt = 0; icnt < numpnts(name); icnt += 1)
			if (strlen(name[icnt]) > 0)
				wList = AddListItem(io + "_" + num2istr(icnt), wList, ";", inf)
			endif
		endfor
		
		return wList
	
	endif
	
	wName = sdf + io + "on"

	if (WaveExists($wName) == 1)
	
		Wave wTemp = $wName // old stim board config wave
	
		for (icnt = 0; icnt < numpnts(wTemp); icnt += 1)
			if (wTemp[icnt] == 1)
				wList = AddListItem(io + "_" + num2istr(icnt), wList, ";", inf)
			endif
		endfor
	
	endif
	
	return wList

End // StimPrefixList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimNameListAll(sdf)
	String sdf // stim data folder
	
	return StimNameList(sdf, "DAC") + StimNameList(sdf, "TTL")

End // StimNameListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimNameList(sdf, io)
	String sdf // stim data folder
	String io // "DAC" or "TTL"
	
	Variable icnt
	String txt, wName, wName2, wList = "", bdf = NMStimBoardDF(sdf)
	
	if ((StringMatch(io, "DAC") == 0) && (StringMatch(io, "TTL") == 0))
		return ""
	endif
	
	wName = bdf + io + "name"
	
	if (WaveExists($wName) == 1)
	
		Wave /T name = $wName // new stim board config wave
		
		for (icnt = 0; icnt < numpnts(name); icnt += 1)
			if (strlen(name[icnt]) > 0)
				txt = io + "_" + num2istr(icnt) + " : " + name[icnt]
				wList = AddListItem(txt, wList, ";", inf)
			endif
		endfor
		
		return wList
		
	endif
	
	wName = sdf + io + "on"
	wName2 = sdf + io + "name"
	
	if ((WaveExists($wName) == 1) && (WaveExists($wName2) == 1))
	
		Wave wTemp = $wName
		Wave /T wTemp2 = $wName2
	
		for (icnt = 0; icnt < numpnts(wTemp); icnt += 1)
			if (wTemp[icnt] == 1)
				txt = io + "_" + num2istr(icnt) + " : " + wTemp2[icnt]
				wList = AddListItem(txt, wList, ";", inf)
			endif
		endfor
	
	endif

	return wList

End // StimNameList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimPulseList(sdf)
	String sdf
	
	String wList = FolderObjectList(sdf, 6)
	
	return ListMatch( wList, "*_pulse", ";" )
	
End // StimPulseList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWaveList(sdf, prefixList, waveNum)
	String sdf // stim data folder
	String prefixList // wave prefix name list
	Variable waveNum // (-1) all
	
	Variable icnt, wcnt, wbgn = waveNum, wend = waveNum
	String wName, wPrefix, wList = ""
	
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	
	if (waveNum == -1)
		wbgn = 0
		wend = NumStimWaves - 1
	endif
	
	for (icnt = 0; icnt < ItemsInList(prefixList); icnt += 1)
	
		wPrefix = StringFromList(icnt,prefixList)

		for (wcnt = wbgn; wcnt <= wend; wcnt += 1)
		
			wName = StimWaveName(wPrefix, -1, wcnt)
			
			if (WaveExists($sdf+wName) == 1) 
				wList = AddListItem(wName,wList,";",inf)
			endif
			
		endfor
	
	endfor

	return wList

End // StimWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimWaveName(prefix, config, waveNum)
	String prefix // wave prefix name ("DAC" or "TTL")
	Variable config // (-1) for none
	Variable waveNum // (-1) for none
	
	if (config >= 0)
		prefix += "_" + num2istr(config)
	endif
	
	if (waveNum >= 0)
		prefix += "_" + num2istr(waveNum)
	endif
	
	return prefix // e.g. "DAC_0_1"

End // StimWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimPrefix(wName)
	String wName
	
	String io = wName[0,2]
	
	strswitch(io)
		case "ADC":
		case "DAC":
		case "TTL":
			break
		default:
			return ""
	endswitch
	
	return io

End // StimPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function StimConfigNum(wName) // determine config num from wave name
	String wName
	
	Variable icnt, found1, found2, config = -1
	
	for (icnt = strlen(wName)-1; icnt > 0; icnt -= 1)
		if (StringMatch(wName[icnt,icnt],"_") == 1)
			if (found2 == 0)
				found2 = icnt
			else
				found1 = icnt
				break
			endif
		endif
	endfor
	
	if (found1 > 0)
		config = str2num(wName[found1+1,found2-1])
	elseif (found2 > 0)
		config = str2num(wName[found2+1, inf])
	endif
	
	return config

End // StimConfigNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimConfigStr(sdf, wName, what)
	String sdf
	String wName
	String what
	
	Variable config
	String ioName, io, df = sdf, bdf = NMStimBoardDF(sdf)
	
	if (DataFolderExists(bdf) == 1)
		df = bdf
	endif
	
	wName = NMChild( wName )
	
	config = StimConfigNum(wName)
	io = StimPrefix(wName)
	
	ioName = df + io + what
	
	if (WaveExists($ioName) == 0)
		return ""
	endif
	
	if ((config < 0) || (config >= numpnts($ioName)))
		return ""
	endif
	
	Wave /T wTemp = $ioName
	
	return wTemp[config]
	
End // StimConfigStr

//****************************************************************
//****************************************************************
//****************************************************************
//
//	subfolder Stim Retrieve Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SubStimCall(fxn)
	String fxn
	
	String df = SubStimDF()
	
	if (strlen(df) == 0)
		NMDoAlert("The current data folder contains no stimulus configuration.")
		return 0
	endif
	
	strswitch(fxn)
	
		case "Details":
			return SubStimDetails()
	
		case "Pulse Table":
			return StimTableCall(SubStimDF(), "All")
			
		case "ADC Table":
			return NMStimBoardConfigTable(SubStimDF(), "ADC", "", 0)
			
		case "DAC Table":
			return NMStimBoardConfigTable(SubStimDF(), "DAC", "", 0)
			
		case "TTL Table":
			return NMStimBoardConfigTable(SubStimDF(), "TTL", "", 0)
			
		case "Stim Waves":
			return SubStimWavesRetrieveCall()
			
	endswitch

End // SubStimCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SubStimDF()

	return SubStimName( "", fullPath = 1 )

End // SubStimDF

//****************************************************************
//****************************************************************
//****************************************************************

Function SubStimDetails()

	String acqStr, sdf = SubStimDF()
	
	Variable acqMode = NumVarOrDefault(sdf+"AcqMode", 0)
	
	NMHistory(NMCR + "Stim: " + RemoveEnding( sdf, ":" ))
	NMHistory("Acquisition Mode: " + NMStimAcqModeStr(acqMode))
	NMHistory("Waves/Groups: " + num2istr(NumVarOrDefault(sdf+"NumStimWaves", 0)))
	NMHistory("Wave Length (ms): " + num2str(NumVarOrDefault(sdf+"WaveLength", 0)))
	NMHistory("Samples per Wave: " + num2istr(NumVarOrDefault(sdf+"SamplesPerWave", Nan)))
	NMHistory("Sample Interval (ms): " + num2str(NumVarOrDefault(sdf+"SampleInterval", Nan)))
	NMHistory("Stim Interlude (ms): " + num2str(NumVarOrDefault(sdf+"InterStimTime", Nan)))
	//NMHistory("Stim Rate (ms): " + num2str(NumVarOrDefault(sdf+"StimRate", Nan)))
	
	NMHistory("Repetitions: " + num2istr(NumVarOrDefault(sdf+"NumStimReps", Nan)))
	NMHistory("Rep Interlude (ms): " + num2str(NumVarOrDefault(sdf+"InterRepTime", Nan)))
	//NMHistory("Rep Rate (ms): " + num2str(NumVarOrDefault(sdf+"RepRate", Nan)))

End // SubStimDetails

//****************************************************************
//****************************************************************
//****************************************************************

Function SubStimWavesRetrieveCall()

	String sdf = SubStimDF()

	String plist = StimPrefixListAll(sdf)
	String pSelect = ""
	
	Variable retrieveAs = NMVarGet( "StimRetrieveAs" )
	
	Prompt retrieveAs, "retrieve as:", popup "DAC/TTL pulse waves;channel waves;"
	
	if (ItemsInlist(plist) > 1)
		Prompt pSelect, "select stim configuration:", popup "All;" + plist
		//DoPrompt "Retrieve Stim Waves To Current Folder", pSelect, retrieveAs
		DoPrompt "Retrieve Stim Waves To Current Folder", pSelect
	else
		//DoPrompt "Retrieve Stim Waves To Current Folder", retrieveAs
		pSelect = plist
	endif
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	if (StringMatch(pSelect, "All") == 1)
		pSelect = plist
	endif
	
	SetNMvar( NMDF+"StimRetrieveAs", retrieveAs )
	
	retrieveAs -= 1
	
	return SubStimWavesRetrieve( pSelect, retrieveAs, history = 1 )

End // SubStimWavesRetrieveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SubStimWavesRetrieve(plist, asChan [ history ] ) // retrieve sub folder stim waves
	String plist // prefix list
	Variable asChan // this option has been deprecated
	Variable history
	
	Variable icnt, wcnt
	String prefix, newprefix, pname, dpName, ioName, ioUnits, wName, wList = ""
	String gName, gTitle, vlist = ""
	
	String sdf = SubStimDF(), bdf = NMStimBoardDF(sdf), df = GetDataFolder(1)
	
	if ( strlen( sdf ) == 0 )
		return -1
	endif
	
	if ( history )
		vlist = NMCmdStr( plist, vlist )
		vlist = NMCmdNum( asChan, vlist )
		NMCommandHistory( vlist )
	endif
	
	Variable pgOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	
	for (icnt = 0; icnt < ItemsInList(plist); icnt += 1)
		
		prefix = StringFromList(icnt, plist)
		pname = prefix + "_pulse"
		dpname = df + pname
		
		StimWavesCheck(sdf, 0)
		
		wList = ""
		
		if (pgOff == 1)
			newPrefix = "My" + prefix
			wList = NMFolderWaveList(sdf, newPrefix + "*", ";", "",0) // user "My" waves
		endif
		
		if (ItemsInList(wList) == 0)
			newPrefix = "u" + prefix
			wList = NMFolderWaveList(sdf, newPrefix + "*", ";", "",0) // unscaled waves for display
		endif
		
		for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
			wName = StringFromList(wcnt, wList)
			Duplicate /O $(sdf + wName) $wName
		endfor
		
		ioName = StimConfigStr(sdf, pname, "name")
		ioUnits = StimConfigStr(sdf, pname, "units")
		
		gName = "MN_" + NMFolderPrefix("") + pname
		gTitle = ioName + " : " + pname
		NMGraph( wList = wList, gName = gName, gTitle = gTitle, xLabel = NMXunits, yLabel = ioUnits, color = "rainbow" )
		NMPrefixAdd(newPrefix)
		
	endfor

End // SubStimWavesRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function StimWavesToChannel(io, config, chanNum)
	String io // DAC or TTL
	Variable config // output config number
	Variable chanNum
	
	Variable wcnt, icnt
	String prefix, wName, oName, olist

	Variable nWaves = NumVarOrDefault("NumWaves", 0)
	
	String wPrefix = StrVarOrDefault("WavePrefix", NMStrGet( "WavePrefix" ))
	
	prefix = io + "_" + num2istr(config)
	
	olist = WaveList(prefix + "*", ";", "")
	
	do
	
		for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		
			oName = StringFromList(icnt, olist)
			wName = GetWaveName("default", chanNum, wcnt)
			
			Duplicate /O $oName $wName
			
			wcnt += 1
			
			if (wcnt == nWaves)
				break
			endif
		
		endfor
	
	while (wcnt < nWaves)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		
		oName = StringFromList(icnt, olist)
		
		if (WaveExists($oName) == 1)
			KillWaves /Z $oName // kill remaining stim waves
		endif
			
	endfor

End // StimWavesToChannel

//****************************************************************
//****************************************************************
//****************************************************************