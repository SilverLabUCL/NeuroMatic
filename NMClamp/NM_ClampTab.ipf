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

StrConstant NMClampTabDF = "root:Packages:NeuroMatic:Clamp:TabObjects:"

Static Constant NumInsOuts = 7

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampTabEnable( enable )
	Variable enable
	
	if ( enable == 1 )
	
		if ( CheckClampTabDF() == 1 ) // to allow updating with new versions
			CheckClampTab2()
		endif
		
		ClampTabMake() // make controls if necessary
		ClampTabUpdate()
		
	else
	
		ClampTabDisable()
		
	endif
	
End // NMClampTabEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckClampTabDF() // check to see if folder exists

	if ( DataFolderExists( NMClampTabDF ) == 0 )
		NewDataFolder $RemoveEnding( NMClampTabDF, ":" )
		return 1
	endif
	
	return 0

End // CheckClampTabDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckClampTab2() // declare Clamp Tab global variables
	
	if ( DataFolderExists( NMClampTabDF ) == 0 )
		return 0 // folder doesnt exist
	endif
	
	CheckNMstr( NMClampTabDF + "TabControlList", "File,CT1_;Stim,CT2_;DAQ,CT3_;Notes,CT4_;" + NMPanelName + ",CT0_Tab;" )
	
	CheckNMvar( NMClampTabDF + "CurrentTab", 0 )
	CheckNMvar( NMClampTabDF + "StatsOn", 0 )
	CheckNMvar( NMClampTabDF + "SpikeOn", 0 )
	
	CheckNMvar( NMClampTabDF + "ADCnum", 0 )
	CheckNMvar( NMClampTabDF + "DACnum", 0 )
	CheckNMvar( NMClampTabDF + "TTLnum", 0 )
	
	CheckNMstr( NMClampTabDF + "ADCname", "" )
	CheckNMstr( NMClampTabDF + "DACname", "" )
	CheckNMstr( NMClampTabDF + "TTLname", "" )
	
	// stim tab
	
	CheckNMstr( NMClampTabDF + "StimTag", "" )
	CheckNMstr( NMClampTabDF + "DataPrefix", NMStrGet( "WavePrefix" ) )
	CheckNMstr( NMClampTabDF + "PreStimFxnList", "" )
	CheckNMstr( NMClampTabDF + "InterStimFxnList", "" )
	CheckNMstr( NMClampTabDF + "PostStimFxnList", "" )
	
	CheckNMvar( NMClampTabDF + "NumStimWaves", NaN )
	CheckNMvar( NMClampTabDF + "WaveLength", NaN )
	
	CheckNMvar( NMClampTabDF + "SampleInterval", NaN )
	CheckNMvar( NMClampTabDF + "SamplesPerWave", NaN )
	
	CheckNMvar( NMClampTabDF + "InterStimTime", NaN )
	CheckNMvar( NMClampTabDF + "StimRate", NaN )
	
	CheckNMvar( NMClampTabDF + "NumStimReps", NaN )
	CheckNMvar( NMClampTabDF + "TotalTime", NaN )
	
	CheckNMvar( NMClampTabDF + "InterRepTime", NaN )
	CheckNMvar( NMClampTabDF + "RepRate", NaN )
	
	// config tab
	
	CheckNMstr( NMClampTabDF + "UnitsList", "V;mV;A;nA;pA;S;nS;pS;" )
	
	CheckNMstr( NMClampTabDF + "IOname", "" )
	CheckNMvar( NMClampTabDF + "IOnum", 0 )
	CheckNMvar( NMClampTabDF + "IOchan", 0 )
	CheckNMvar( NMClampTabDF + "IOscale", 1 )
	//CheckNMvar( NMClampTabDF + "IOmisc", NaN ) // NOT USED ANYMORE
	
	// pulse gen tab
	
	CheckNMstr( NMClampTabDF + "PulsePrefix", "" )
	//CheckNMvar( NMClampTabDF + "PulseShape", 1 ) // NOT USED ANYMORE
	//CheckNMvar( NMClampTabDF + "PulseWaveN", 0 )
	//CheckNMvar( NMClampTabDF + "PulseWaveND", 0 )
	//CheckNMvar( NMClampTabDF + "PulseAmp", 1 )
	//CheckNMvar( NMClampTabDF + "PulseAmpD", 0 )
	//CheckNMvar( NMClampTabDF + "PulseOnset", 0 )
	//CheckNMvar( NMClampTabDF + "PulseOnsetD", 0 )
	//CheckNMvar( NMClampTabDF + "PulseWidth", 1 )
	//CheckNMvar( NMClampTabDF + "PulseWidthD", 0 )
	//CheckNMvar( NMClampTabDF + "PulseTau2", 0 )
	//CheckNMvar( NMClampTabDF + "PulseTau2D", 0 )
	
	// pulse/stim display variables
	
	CheckNMvar( NMClampTabDF + "PulseAllOutputs", 0 )
	CheckNMvar( NMClampTabDF + "PulseAllWaves", 1 )
	CheckNMvar( NMClampTabDF + "PulseWaveNum", 0 )
	
End // CheckClampTab2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampFindShortName( ctrlName )
	String ctrlName
	
	if ( strsearch( ctrlName, "ADC", 0, 2 ) > 0 )
		return "ADC"
	elseif ( strsearch( ctrlName, "DAC", 0, 2 ) > 0 )
		return "DAC"
	elseif ( strsearch( ctrlName, "TTL", 0, 2 ) > 0 )
		return "TTL"
	elseif ( strsearch( ctrlname, "Misc", 0, 2 ) > 0 )
		return "Misc"
	elseif ( strsearch( ctrlname, "Time", 0, 2 ) > 0 )
		return "Time"
	elseif ( strsearch( ctrlname, "Board", 0, 2 ) > 0 )
		return "Board"
	elseif ( strsearch( ctrlname, "Pulse", 0, 2 ) > 0 )
		return "Pulse"
	endif
	
	return ""

End // ClampFindShortName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabMake()

	Variable icnt, x0, y0, xinc, yinc, fs = NMPanelFsize
	Variable nDACon = 4
	Variable nADCon = 8
	Variable nTTLon = 4
	
	String cdf = NMClampDF, tdf = NMClampTabDF, ndf = NMNotesDF
	
	STRUCT NMRGB c
	STRUCT NMRGB c2
	STRUCT NMPulseLBWaves lbp
	STRUCT NMClampNotesLBWaves lbn

	ControlInfo /W=$NMPanelName CT0_StimList 
	
	if ( V_Flag != 0 )
		return 0 // tab controls already exist
	endif
	
	if ( WinType( NMPanelName ) != 7 )
		return -1
	endif
	
	DoWindow /F $NMPanelName
	
	x0 = 20
	y0 = NMPanelTabY + 40
	yinc = 30
	
	NMColorList2RGB( NMWinColor, c )
	NMColorList2RGB( NMWinColor2, c2 )
	
	GroupBox CT0_StimGrp, title = "", pos={x0,y0-10}, size={260,70}, labelBack=(c2.r,c2.g,c2.b), fsize=fs, win=$NMPanelName
	
	PopupMenu CT0_StimList, pos={x0+240,y0}, size={0,0}, bodyWidth=220, mode=1, value=" ", proc=StimListPopup, fsize=fs, win=$NMPanelName
	
	Button CT0_StartPreview, title="Preview", pos={x0+35,y0+yinc}, size={60,20}, proc=ClampButton, fsize=fs, win=$NMPanelName
	Button CT0_StartRecord, title="Record", pos={x0+110,y0+yinc}, size={60,20}, proc=ClampButton, fsize=fs, win=$NMPanelName
	Button CT0_Note, title="Note", pos={x0+185,y0+yinc}, size={40,20}, proc=ClampButton, fsize=fs, win=$NMPanelName
	
	//SetVariable CT0_ErrorMssg, title=" ", pos={x0,587}, size={260,50}, value=$cdf+ "ClampErrorStr", fsize=fs, win=$NMPanelName
	
	Checkbox CT0_DemoMode, pos={x0+180,615}, title="Demo Mode", size={10,20}, mode=0, win=$NMPanelName
	Checkbox CT0_DemoMode, value=0, proc=NMClampTabCheckbox, fsize=fs, win=$NMPanelName
	
	TabControl CT0_Tab, pos={2, NMPanelTabY+110}, size={NMPanelWidth-4, 640}, labelBack=(c.r,c.g,c.b), proc=ClampTabControl, fsize=fs, win=$NMPanelName
	
	MakeTabs( StrVarOrDefault( tdf + "TabControlList", "" ) )
	
	// File tab
	
	y0 = NMPanelTabY + 145
	xinc = 15
	yinc = 23
	
	GroupBox CT1_DataGrp, title = "Folders", pos={x0,y0}, size={260,118}, fsize=fs, win=$NMPanelName
	
	SetVariable CT1_FilePrefix, title= "prefix", pos={x0+xinc,y0+1*yinc}, size={125,50}, fsize=fs, win=$NMPanelName
	SetVariable CT1_FilePrefix, value=$cdf+"FolderPrefix", proc=FileTabSetVariable, win=$NMPanelName
	
	SetVariable CT1_FileCellSet, title= "cell", pos={x0+150,y0+1*yinc}, size={65,50}, fsize=fs, win=$NMPanelName
	SetVariable CT1_FileCellSet, limits={0,inf,0}, value=$cdf+"DataFileCell", proc=FileTabSetVariable, win=$NMPanelName
	
	Button CT1_FileNewCell, title="+", pos={x0+225,y0+1*yinc-2}, size={20,20}, proc=FileTabButton, fsize=fs, win=$NMPanelName
	
	SetVariable CT1_StimSuffix, title= "suffix", pos={x0+xinc,y0+2*yinc}, size={125,50}, fsize=fs, win=$NMPanelName
	SetVariable CT1_StimSuffix, value=$tdf + "StimTag", proc=FileTabSetVariable, win=$NMPanelName
	
	SetVariable CT1_FileSeqSet, title= "seq", pos={x0+150,y0+2*yinc}, size={65,50}, fsize=fs, win=$NMPanelName
	SetVariable CT1_FileSeqSet, limits={0,inf,0}, value=$cdf+"DataFileSeq", win=$NMPanelName
	
	SetVariable CT1_FilePathSet, title= "save to", pos={x0+xinc,y0+3*yinc}, size={230,50}, fsize=fs, win=$NMPanelName
	SetVariable CT1_FilePathSet, value=$cdf+"ClampPath", proc=FileTabSetVariable, win=$NMPanelName
	
	Checkbox CT1_SaveConfig, pos={x0+xinc,y0+4*yinc}, title="save", size={10,20}, fsize=fs, win=$NMPanelName
	Checkbox CT1_SaveConfig, value=0, proc=FileTabCheckbox, win=$NMPanelName
	
	Checkbox CT1_CloseFolder, pos={x0+155,y0+4*yinc}, title="auto close", size={10,20}, fsize=fs, win=$NMPanelName
	Checkbox CT1_CloseFolder, value=0, proc=FileTabCheckbox, win=$NMPanelName
	
	y0 += 130
	yinc = 24
	
	GroupBox CT1_NotesGrp, title = "Notes", pos={x0,y0}, size={150,125}, fsize=fs, win=$NMPanelName
	
	SetVariable CT1_UserName, title= "name:", pos={x0+xinc,y0+1*yinc}, size={120,50}, fsize=fs, win=$NMPanelName
	SetVariable CT1_UserName, value=$ndf+"H_Name", proc=FileTabSetVariable, win=$NMPanelName
	
	SetVariable CT1_UserLab, title= "lab:", pos={x0+xinc,y0+2*yinc}, size={120,50}, fsize=fs, win=$NMPanelName
	SetVariable CT1_UserLab, value=$ndf+"H_Lab", proc=FileTabSetVariable, win=$NMPanelName
	
	SetVariable CT1_ExpTitle, title= "title:", pos={x0+xinc,y0+3*yinc}, size={120,50}, fsize=fs, win=$NMPanelName
	SetVariable CT1_ExpTitle, value=$ndf+"H_Title", proc=FileTabSetVariable, win=$NMPanelName
	
	Button CT1_NotesEdit, title="Edit All", pos={x0+50,y0+4*yinc}, size={55,20}, proc=FileTabButton, fsize=fs, win=$NMPanelName
	
	GroupBox CT1_LogGrp, title = "Log", pos={x0+165,y0}, size={95,125}, fsize=fs, win=$NMPanelName
	
	PopupMenu CT1_LogMenu, pos={x0+245,y0+1*yinc}, size={0,0}, bodyWidth=65, proc=FileTabPopup, win=$NMPanelName
	PopupMenu CT1_LogMenu, value="Display;---;None;Text;Table;Both;", mode=1, fsize=fs, win=$NMPanelName
	
	Checkbox CT1_LogAutoSave, pos={x0+180,y0+3*yinc}, title="auto save", size={10,20}, win=$NMPanelName
	Checkbox CT1_LogAutoSave, value=0, proc=FileTabCheckbox, fsize=fs, win=$NMPanelName
	
	// Stim Tab
	
	y0 = NMPanelTabY + 155
	xinc = 68
	yinc = 23
	
	TitleBox CT2_StimName, win=$NMPanelName, pos={x0+15,y0-20}, size={250,18}, fsize=fs, fixedSize=1, disable=1
	TitleBox CT2_StimName, win=$NMPanelName, frame=0, title=""
	
	GroupBox CT2_SelectGrp, title = "", pos={x0,y0}, size={260,30}, disable=1, fsize=fs, labelBack=(c2.r,c2.g,c2.b), win=$NMPanelName
	
	Checkbox CT2_MiscCheck, pos={x0+10,y0+10}, title="Misc", size={10,20}, mode=1, win=$NMPanelName
	Checkbox CT2_MiscCheck, value=0, proc=StimTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	Checkbox CT2_TimeCheck, pos={x0+1*xinc-3,y0+10}, title="Time", size={10,20}, mode=1, win=$NMPanelName
	Checkbox CT2_TimeCheck, value=0, proc=StimTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	Checkbox CT2_Boardcheck, pos={x0+2*xinc-13,y0+10}, title="Ins / Outs", size={10,20}, mode=1, win=$NMPanelName
	Checkbox CT2_Boardcheck, value=0, proc=StimTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	Checkbox CT2_Pulsecheck, pos={x0+3*xinc,y0+10}, title="Pulse", size={10,20}, mode=1, win=$NMPanelName
	Checkbox CT2_Pulsecheck, value=0, proc=StimTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	// Stim Misc Tab
	
	y0 = NMPanelTabY + 155 + 45
	xinc = 65
	yinc = 25
	
	Checkbox CT2_ChainCheck, pos={x0+10,y0}, title="chain", size={10,20}, fsize=fs, win=$NMPanelName
	Checkbox CT2_ChainCheck, value=0, proc=StimTabCheckbox, disable=1, win=$NMPanelName
	
	Checkbox CT2_StatsCheck, pos={x0+10+1*xinc,y0}, title="stats", size={10,20}, fsize=fs, win=$NMPanelName
	Checkbox CT2_StatsCheck, value=0, proc=StimTabCheckbox, disable=1, win=$NMPanelName
	
	Checkbox CT2_SpikeCheck, pos={x0+10+2*xinc,y0}, title="spike", size={10,20}, fsize=fs, win=$NMPanelName
	Checkbox CT2_SpikeCheck, value=0, proc=StimTabCheckbox, disable=1, win=$NMPanelName
	
	//Checkbox CT2_PNCheck, pos={x0+10+3*xinc,y0}, title="P / N", size={10,20}, fsize=fs, win=$NMPanelName
	//Checkbox CT2_PNCheck, value=0, proc=StimTabCheckbox, disable=1, win=$NMPanelName
	
	y0 += 10
	
	SetVariable CT2_StimSuffix, title= "file name suffix", pos={x0+10,y0+1*yinc}, size={170,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_StimSuffix, value=$tdf + "StimTag", proc=StimTabSetVariable, disable=1, win=$NMPanelName
	
	SetVariable CT2_ADCprefix, title= "wave name prefix", pos={x0+10,y0+2*yinc}, size={170,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_ADCprefix, value=$tdf + "DataPrefix", proc=StimTabSetVariable, disable=1, win=$NMPanelName
	
	yinc = 30
	
	PopupMenu CT2_MacroBefore, title="macros", pos={x0+115,y0+3*yinc}, size={0,0}, bodywidth=65, win=$NMPanelName
	PopupMenu CT2_MacroBefore, mode=1, value="before", proc=StimTabFxnPopup, disable=1, fsize=fs, win=$NMPanelName
	
	PopupMenu CT2_MacroDuring, title="macros", pos={x0+115,y0+4*yinc}, size={0,0}, bodywidth=65, win=$NMPanelName
	PopupMenu CT2_MacroDuring, mode=1, value="during", proc=StimTabFxnPopup, disable=1, fsize=fs, win=$NMPanelName
	
	PopupMenu CT2_MacroAfter, title="macros", pos={x0+115,y0+5*yinc}, size={0,0}, bodywidth=65, win=$NMPanelName
	PopupMenu CT2_MacroAfter, mode=1, value="after", proc=StimTabFxnPopup, disable=1, fsize=fs, win=$NMPanelName
	
	SetVariable CT2_MacroBeforeList, title= " ", pos={x0+120,y0+3*yinc+2}, size={150,50}, fsize=fs, frame=0, win=$NMPanelName
	SetVariable CT2_MacroBeforeList, value=$tdf + "PreStimFxnList", proc=StimTabSetVariable, disable=1, win=$NMPanelName
	
	SetVariable CT2_MacroDuringList, title= " ", pos={x0+120,y0+4*yinc+2}, size={150,50}, fsize=fs, frame=0, win=$NMPanelName
	SetVariable CT2_MacroDuringList, value=$tdf + "InterStimFxnList", proc=StimTabSetVariable, disable=1, win=$NMPanelName
	
	SetVariable CT2_MacroAfterList, title= " ", pos={x0+120,y0+5*yinc+2}, size={150,50}, fsize=fs, frame=0, win=$NMPanelName
	SetVariable CT2_MacroAfterList, value=$tdf + "PostStimFxnList", proc=StimTabSetVariable, disable=1, win=$NMPanelName
	
	// Stim Time Tab
	
	y0 = NMPanelTabY + 155 + 42
	xinc = 15
	yinc = 23
	
	PopupMenu CT2_AcqMode, title=" ", pos={x0+150,y0}, size={0,0}, bodywidth=150, fsize=fs, win=$NMPanelName
	PopupMenu CT2_AcqMode, mode=1, value="continuous;episodic;", proc=StimTabPopup, disable=1, win=$NMPanelName
	
	PopupMenu CT2_TauDAC, title=" ", pos={x0+260,y0}, size={0,0}, bodywidth=100, fsize=fs, win=$NMPanelName
	PopupMenu CT2_TauDAC, mode=1, value="", proc=StimTabPopup, disable=1, win=$NMPanelName
	
	y0 +=30
	
	GroupBox CT2_WaveGrp, title = "Waves", pos={x0,y0}, size={260,98}, disable=1, fsize=fs, win=$NMPanelName
	
	SetVariable CT2_NumStimWaves, title= "number", pos={x0+xinc,y0+1*yinc}, size={110,50}, limits={1,inf,0}, win=$NMPanelName
	SetVariable CT2_NumStimWaves, value=$tdf + "NumStimWaves", proc=StimTabSetTau, disable=1, fsize=fs, win=$NMPanelName
	
	SetVariable CT2_WaveLength, title= "length (ms)", pos={x0+xinc+120,y0+1*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_WaveLength, limits={0.001,inf,0}, value=$tdf + "WaveLength", proc=StimTabSetTau, disable=1, win=$NMPanelName
	
	SetVariable CT2_SampleInterval, title= "dt (ms)", pos={x0+xinc,y0+2*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_SampleInterval, limits={0.001,inf,0}, value=$tdf + "SampleInterval", proc=StimTabSetTau, disable=1, win=$NMPanelName
	
	SetVariable CT2_SamplesPerWave, title= "samples :", pos={x0+xinc+120,y0+2*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_SamplesPerWave, limits={0,inf,0}, value=$tdf + "SamplesPerWave", proc=StimTabSetTau, disable=1, frame=0, win=$NMPanelName
	
	SetVariable CT2_InterStimTime, title= "interlude (ms)", pos={x0+xinc,y0+3*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_InterStimTime, limits={0,inf,0}, value=$tdf + "InterStimTime", proc=StimTabSetTau, disable=1, win=$NMPanelName
	
	SetVariable CT2_StimRate, title= "stim rate (Hz) :", pos={x0+xinc+120,y0+3*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_StimRate, limits={0,inf,0}, value=$tdf + "StimRate", proc=StimTabSetTau, disable=1, frame=0, win=$NMPanelName
	
	y0 += 105
	
	GroupBox CT2_RepGrp, title = "Repetitions", pos={x0,y0}, size={260,76}, disable=1, fsize=fs, win=$NMPanelName
	
	SetVariable CT2_NumStimReps, title= "number", pos={x0+xinc,y0+1*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_NumStimReps, limits={1,inf,0}, value=$tdf + "NumStimReps", proc=StimTabSetTau, disable=1, win=$NMPanelName
	
	SetVariable CT2_TotalTime, title= "total time (sec) :", pos={x0+xinc+120,y0+1*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_TotalTime, limits={0,inf,0}, value=$tdf + "TotalTime", disable=1, frame=0, noedit=1, win=$NMPanelName
	
	SetVariable CT2_InterRepTime, title= "interlude (ms)", pos={x0+xinc,y0+2*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_InterRepTime, limits={0,inf,0}, value=$tdf + "InterRepTime", proc=StimTabSetTau, disable=1, win=$NMPanelName
	
	SetVariable CT2_RepRate, title= "rep rate (Hz) :", pos={x0+xinc+120,y0+2*yinc}, size={110,50}, fsize=fs, win=$NMPanelName
	SetVariable CT2_RepRate, limits={0,inf,0}, value=$tdf + "RepRate", proc=StimTabSetTau, disable=1, frame=0, win=$NMPanelName
	
	// Stim Board Tab
	
	y0 = NMPanelTabY + 155 + 60
	xinc = 86
	yinc = 20
	
	GroupBox CT2_ADCgrp, title = "ADC in", pos={x0,y0-18}, size={xinc+2,165}, disable=1, fsize=fs, labelBack=(c.r,c.g,c.b), win=$NMPanelName
	
	for ( icnt = 0; icnt < NumInsOuts; icnt += 1 )
		PopupMenu $"CT2_ADC"+num2istr( icnt ),pos={x0+4,y0+icnt*yinc}, size={80,0}, bodywidth=80, disable=1, win=$NMPanelName
		PopupMenu $"CT2_ADC"+num2istr( icnt ), mode=1, title="", value="", proc=StimTabIOPopup, fsize=fs, win=$NMPanelName
	endfor
	
	GroupBox CT2_DACgrp, title = "DAC out", pos={x0+xinc,y0-18}, size={xinc+2,165}, disable=1, fsize=fs, labelBack=(c.r,c.g,c.b), win=$NMPanelName
	
	for ( icnt = 0; icnt < NumInsOuts; icnt += 1 )
		PopupMenu $"CT2_DAC"+num2istr( icnt ),pos={x0+1*xinc+4,y0+icnt*yinc}, size={80,0}, bodywidth=80, disable=1, win=$NMPanelName
		PopupMenu $"CT2_DAC"+num2istr( icnt ), mode=1, title="", value="", proc=StimTabIOPopup, fsize=fs, win=$NMPanelName
	endfor
	
	GroupBox CT2_TTLgrp, title = "TTL out", pos={x0+2*xinc,y0-18}, size={xinc+2,165}, disable=1, fsize=fs, labelBack=(c.r,c.g,c.b), win=$NMPanelName
	
	for ( icnt = 0; icnt < NumInsOuts; icnt += 1 )
		PopupMenu $"CT2_TTL"+num2istr( icnt ),pos={x0+2*xinc+4,y0+icnt*yinc}, size={80,0}, bodywidth=80, disable=1, win=$NMPanelName
		PopupMenu $"CT2_TTL"+num2istr( icnt ), mode=1, title="", value="", proc=StimTabIOPopup, fsize=fs, win=$NMPanelName
	endfor
	
	y0 += 5
	
	Checkbox CT2_GlobalConfigs, pos={x0+5,y0+8*yinc}, title="use global configs", size={10,20}, win=$NMPanelName
	Checkbox CT2_GlobalConfigs, value=1, proc=StimTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	Button CT2_IOtable, title="Table", pos={x0+150,y0+8*yinc}, size={55,20}, proc=StimTabButton, disable=1, fsize=fs, win=$NMPanelName
	
	// Stim Pulse Tab
	
	y0 = NMPanelTabY + 155 + 40
	xinc = 105
	yinc = 30
	
	PopupMenu CT2_WavePrefix,pos={x0+170,y0}, size={0,0}, bodywidth=150, disable=1, win=$NMPanelName
	PopupMenu CT2_WavePrefix, mode=1, title="", value="", proc=PulseTabPopup, fsize=fs, win=$NMPanelName
	
	Button CT2_Display, title="Plot", pos={x0+190,y0}, size={50,20}, proc=PulseTabButton, disable=1, fsize=fs, win=$NMPanelName
	
	NMClampPulseLBWavesDefault( lbp )
	
	y0 += 30
	
	Listbox CT2_PulseConfigs, pos={x0,y0}, size={260,80}, disable=1, fsize=fs, listWave=$lbp.lb1wName, selWave=$lbp.lb1wNameSel, win=$NMPanelName
	Listbox CT2_PulseConfigs, mode=1, userColumnResize=1, proc=NMClampPulseLB1Control, widths={25,1500}, win=$NMPanelName
	
	y0 += 90
	
	Listbox CT2_PulseParams, pos={x0,y0}, size={260,115}, disable=1, fsize=fs, listWave=$lbp.lb2wName, selWave=$lbp.lb2wNameSel, win=$NMPanelName
	Listbox CT2_PulseParams, mode=1, userColumnResize=1, selRow=-1, proc=NMClampPulseLB2Control, widths={35,70,45}, win=$NMPanelName
	
	Checkbox CT2_UseMyWaves, pos={x0+70,615}, title="use \"My\" waves", size={10,20}, win=$NMPanelName
	Checkbox CT2_UseMyWaves, value=1, disable=1, proc=PulseTabCheckbox, fsize=fs, win=$NMPanelName
	
	// Config Tab
	
	y0 = NMPanelTabY + 140
	xinc = 90
	yinc = 28
	
	GroupBox CT3_SelectGrp, title = "", pos={x0,y0}, size={260,65}, disable=1, fsize=fs, labelBack=(c2.r,c2.g,c2.b), win=$NMPanelName
	
	Checkbox CT3_ADCcheck, pos={x0+10,y0+10}, title="ADC in", size={10,20}, mode=1, win=$NMPanelName
	Checkbox CT3_ADCcheck, value=1, proc=ConfigsTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	Checkbox CT3_DACcheck, pos={x0+10+1*xinc,y0+10}, title="DAC out", size={10,20}, mode=1, win=$NMPanelName
	Checkbox CT3_DACcheck, value=0, proc=ConfigsTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	Checkbox CT3_TTLcheck, pos={x0+10+2*xinc,y0+10}, title="TTL out", size={10,20}, mode=1, win=$NMPanelName
	Checkbox CT3_TTLcheck, value=0, proc=ConfigsTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	x0 = 2
	y0 += 5
	xinc = 28
	yinc = 30
	
	for ( icnt = 0; icnt < 7; icnt += 1 )
		Button $"CT3_IObnum"+num2istr( icnt ), title=num2istr( icnt ), pos={x0+( icnt+1 )*xinc,y0+1*yinc}, win=$NMPanelName
		Button $"CT3_IObnum"+num2istr( icnt ), size={20,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=$NMPanelName
	endfor
	
	SetVariable CT3_IOnum,pos={x0+55+6*xinc+2,y0+1*yinc+2}, size={40,15},limits={0,20,1}, title=" ", win=$NMPanelName
	SetVariable CT3_IOnum, value=$tdf + "IOnum", proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=$NMPanelName
	
	x0 = 20
	y0 += 100
	xinc = 15
	yinc = 32
	
	GroupBox CT3_IOgrp2, title = "Configuration", pos={x0,y0-25}, size={260,120}, disable=1, fsize=fs, win=$NMPanelName
	
	PopupMenu CT3_IOboard, title="board", pos={x0+143,y0}, size={0,0}, bodywidth=100, win=$NMPanelName
	PopupMenu CT3_IOboard, mode=1, value=" ", proc=ConfigsTabPopup, disable=1, fsize=fs, win=$NMPanelName
	
	PopupMenu CT3_IOunits, title="units", pos={x0+243,y0}, size={0,0}, proc=ConfigsTabPopup, win=$NMPanelName
	PopupMenu CT3_IOunits,bodywidth=55, mode=1, value="V;", disable=1, fsize=fs, win=$NMPanelName
	
	SetVariable CT3_IOchan, title= "chan", pos={x0+xinc,y0+1*yinc}, size={75,50}, limits={0,inf,1}, win=$NMPanelName
	SetVariable CT3_IOchan, value=$tdf + "IOchan", proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=$NMPanelName
	
	SetVariable CT3_IOscale, title= "scale ( V/V )", pos={x0+106,y0+1*yinc}, size={140,50}, limits={-inf,inf,0}, win=$NMPanelName
	SetVariable CT3_IOscale, value=$tdf + "IOscale", proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=$NMPanelName
	
	SetVariable CT3_IOname, title= "name", pos={x0+xinc,y0+2*yinc}, size={115,50}, win=$NMPanelName
	SetVariable CT3_IOname, value=$tdf + "IOname", proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=$NMPanelName
	
	//SetVariable CT3_IOmisc, title= "misc", pos={x0+140,y0+2*yinc}, size={105,50}, limits={-inf,inf,0}, win=$NMPanelName
	//SetVariable CT3_IOmisc, value=$tdf + "IOmisc", proc=ConfigsTabSetVariable, disable=1, fsize=fs, win=$NMPanelName
	
	Checkbox CT3_ADCpresamp, pos={x0+140,y0+2*yinc}, title="PreSamp/TeleGrph", size={10,20}, win=$NMPanelName
	Checkbox CT3_ADCpresamp, value=0, proc=ConfigsTabCheckbox, disable=1, fsize=fs, win=$NMPanelName
	
	y0 += 120
	xinc = 64
	
	Button CT3_IOtable, title="Table", pos={x0+10,y0}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=$NMPanelName
	Button CT3_IOreset, title="Reset", pos={x0+10+1*xinc,y0}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=$NMPanelName
	Button CT3_IOextract, title="Extract", pos={x0+10+2*xinc,y0}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=$NMPanelName
	Button CT3_IOsave, title="Save", pos={x0+10+3*xinc,y0}, size={50,20}, proc=ConfigsTabButton, disable=1, fsize=fs, win=$NMPanelName
	
	// Notes Tab
	
	NMClampNotesLBWavesDefault( lbn )
	
	y0 = NMPanelTabY + 140
	xinc = 90
	yinc = 28
	
	Listbox CT4_NotesHeader, pos={x0,y0}, size={260,80}, disable=1, fsize=fs, listWave=$lbn.header, win=$NMPanelName
	Listbox CT4_NotesHeader, mode=1, userColumnResize=1, selRow=-1, proc=NMClampNotesLBControl, widths={20,60,80,15}, win=$NMPanelName
	
	y0 += 100
	
	Listbox CT4_NotesFile, pos={x0,y0}, size={260,80}, disable=1, fsize=fs, listWave=$lbn.file, win=$NMPanelName
	Listbox CT4_NotesFile, mode=1, userColumnResize=1, selRow=-1, proc=NMClampNotesLBControl, widths={20,60,80,15}, win=$NMPanelName
	
	y0 += 100
	
	Listbox CT4_NotesAcq, pos={x0,y0}, size={260,80}, disable=1, fsize=fs, listWave=$lbn.acq, win=$NMPanelName
	Listbox CT4_NotesAcq, mode=1, userColumnResize=1, selRow=-1, proc=NMClampNotesLBControl, widths={20,200}, win=$NMPanelName
	
	SetNMvar( tdf + "CurrentTab", 0 )

End // ClampTabMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabUpdate()
	
	ControlInfo /W=$NMPanelName CT0_StimList 
	
	if ( V_Flag == 0 )
		return 0 // tab controls dont exist
	endif
	
	StimCurrentCheck()
	
	Variable select = WhichListItem( StimCurrent(), StimMenuList(), ";", 0, 0 ) + 1
	
	PopupMenu CT0_StimList, win=$NMPanelName, mode=select, value=StimMenuList()
	
	TitleBox CT2_StimName, win=$NMPanelName, title = StimCurrent()
	
	Checkbox CT0_DemoMode, win=$NMPanelName, value=NumVarOrDefault( NMClampDF + "DemoMode", 1 )
	
	Variable currentTab = NumVarOrDefault( NMClampTabDF + "CurrentTab", 0 )
	
	String TabList = StrVarOrDefault( NMClampTabDF + "TabControlList", "" )
	String TabName = StringFromList( currentTab, TabList )
	
	TabName = StringFromList( 0, TabName, "," ) // current tab name
	
	EnableTab( currentTab, TabList, 1 )
	
	Execute /Z TabName + "Tab( 1 )"

End // ClampTabUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabDisable()
	Variable icnt
	
	String tlist = StrVarOrDefault( NMClampTabDF+"TabControlList", "" )

	for ( icnt = 0; icnt < ItemsInList( tlist )-1; icnt += 1 )
		EnableTab( icnt, tlist, 0 ) // disable tab controls
	endfor

End // ClampTabDisable

//****************************************************************
//****************************************************************
//
//	Listbox Functions
//
//	lbwName - listbox wave name (full path)
// pcwName // pulse config wave name (full path), see PulseConfigWaveName()
//	pcvName - pulse config variable name (full path)
//	event code: 1-mouse down, 2-mouse up, 4-cell selection, 6-begin cell edit, 7-finish cell edit
//
//****************************************************************
//****************************************************************

Function NMClampPulseLBWavesDefault( lb )
	STRUCT NMPulseLBWaves &lb
	
	lb.pcwName = PulseConfigWaveName()
	lb.lb1wName = NMClampTabDF + "LB1Configs"
	lb.lb1wNameSel = NMClampTabDF + "LB1ConfigsEditable"
	lb.lb2wName = NMClampTabDF + "LB2Configs"
	lb.lb2wNameSel = NMClampTabDF + "LB2ConfigsEditable"
	lb.pcvName = NMClampTabDF + "LB1ConfigNum"
	
	NMPulseLBWavesCheck( lb )
	
End // NMClampPulseLBWavesDefault

//****************************************************************
//****************************************************************

Function NMClampPulseLB1Control( ctrlName, row, col, event ) : ListboxControl
	String ctrlName // name of this control
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
	
	Variable TTL
	String trainStr, titleStr, pstr = ""
	String sdf = StimDF()
	
	String pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	String pcwName = PulseConfigWaveName()
	
	Variable numWaves = NumVarOrDefault( sdf + "NumStimWaves", 0 )
	
	STRUCT NMPulseLBWaves lb
	
	NMClampPulseLBWavesDefault( lb )
	
	if ( event == 2 )
	
		if ( strlen( pPrefix ) == 0 )
			DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
			return -1
		endif
		
		if ( numWaves <= 0 )
			DoAlert 0, "No stimulus waves to add pulses."
			return -1
		endif
	
	endif
	
	if ( StringMatch( pPrefix[ 0, 2 ], "TTL" ) )
		TTL = 1
	endif
	
	String estr = NMPulseLB1Event( row, col, event, lb )
	
	if ( StringMatch( estr, "+" ) )
		pstr = PulseConfigAdd( TTL = TTL )
	elseif ( StringMatch( estr, "-" ) )
		pstr = NMPulseLB1PromptOODE( lb, sdf )
		NMPulseLB1OODE( lb, sdf, pstr )
	else
		NMPulseLB2Update( lb )
		return 0
	endif
	
	NMPulseLB1Update( lb )
	NMPulseLB2Update( lb )
	
	if ( strlen( pstr ) > 0 )
		StimWavesCheck( sdf, 1 )
	endif
	
	PulseGraph( 0 )
	
	return 0
	
End // NMClampPulseLB1Control

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseConfigAdd( [ TTL ] )
	Variable TTL
	
	String paramList = "", sdf = StimDF()
	
	String pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	String pcwName = PulseConfigWaveName()
	
	Variable numWaves = NumVarOrDefault( sdf + "NumStimWaves", 0 )
	Variable waveLength = NumVarOrDefault( sdf + "WaveLength", inf )
	
	Variable binom = NumVarOrDefault( NMClampDF + "PulsePromptBinomial", 0 )
	Variable plasticity = NumVarOrDefault( NMClampDF + "PulsePromptPlasticity", 0 )
	String DSC = StrVarOrDefault( NMClampDF + "PulsePromptTypeDSC", "delta" )
	
	String ampUnits = StimConfigStr( sdf, pPrefix, "units" )
	
	paramList = NMPulsePrompt( udf=sdf, pdf=NMClampTabDF, numWaves=numWaves, timeLimit=waveLength, paramList=paramList, TTL=TTL, titleEnding=pPrefix, binom=binom, plasticity=plasticity, DSC=DSC, timeUnits=NMXunits, ampUnits=ampUnits )
	
	if ( ItemsInList( paramList ) > 0 )
		NMPulseConfigWaveSave( pcwName, paramList )
	endif
	
	return paramList
	
End // PulseConfigAdd

//****************************************************************
//****************************************************************

Function NMClampPulseLB2Control( ctrlName, row, col, event ) : ListboxControl
	String ctrlName // name of this control
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
	
	Variable TTL, configNum, pvar
	
	STRUCT NMPulseLBWaves lb
	
	NMClampPulseLBWavesDefault( lb )
	
	String sdf = StimDF()
	String pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	
	if ( strlen( lb.pcwName ) == 0 )
	
		if ( event == 2 )
			NMDoAlert( "There is currently no selected DAC or TTL output for this stimulus protocol." )
		endif
		
		return -1
		
	endif
	
	if ( StringMatch( pPrefix[ 0, 2 ], "TTL" ) )
		TTL = 1
	endif
	
	configNum = NumVarOrDefault( lb.pcvName, 0 )
	
	pvar = NMPulseLB2Event( row, col, event, lb, TTL=TTL )
	
	if ( pvar >= 0)
		NMPulseLB1Update( lb )
		NMPulseLB2Update( lb )
		StimWavesCheck( sdf, 1 )
		PulseGraph( 0 )
	endif

End // NMClampPulseLB2Control

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimMenuList()

	String d = "---;"
	String mList = "Stimulus Protocols;" + d + " ;" + StimList() + " ;"

	return mList + d + "Open;Save;Save As;Close;Reload;" + d + "Save All;Close All;" + d + "New;Copy;Rename;Retrieve;" + d + "Set Stim List;Set Stim Path;"

End // StimMenuList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimCall( select )
	String select
	
	Variable new, ask, stimexists
	
	String sname = "", newName = ""
	String gdf, dp = NMStimsDF, sdf = StimDF()
	String slist = StimList()
	
	String currentStim = StimCurrent()
	String currentFile = StrVarOrDefault( sdf + "CurrentFile", "" )
	
	if ( strlen( currentStim ) > 0 )
		stimexists = 1
	endif
	
	ClampGraphsCopy( -1, 1 )
	
	strswitch( select )
		
		case "New":
			sname = NMStimNew( "" )
			StimCurrentSet( sname )
			break
			
		case "Open":
		case "Open All":
			sname = NMStimOpen( 1, "ClampStimPath", "" ) // open with dialogue
			break
			
		case "Reload":
			NMStimClose( currentStim )
			sname = NMStimOpen( 0, "ClampStimPath", currentFile ) // open without dialogue
			break
			
		case "Save As":
			new = 1; ask = 1
	
		case "Save":
		
			if ( stimexists == 0 )
				break
			endif
			
			if ( NMStimStatsOn() == 1 )
				NMStimStatsUpdate()
				ClampStatsDisplaySavePositions()
			endif
			
			if ( NMStimSpikeOn() == 1 )
				ClampSpikeDisplaySavePosition()
			endif
			
			ClampGraphsCopy( -1, 1 )
			
			sname = NMStimSave( ask, new, currentStim )
			
			if ( StringMatch( sname, currentStim ) == 0 )
				StimCurrentSet( sname )
			endif
			
			break
			
		case "Save All":
			
			if ( ItemsInList( slist ) == 0 )
				break
			endif
		
			DoAlert 1, "Save all stimulus protocols to disk?"
			
			if ( V_flag != 1 )
				break
			endif
			
			if ( NMStimStatsOn() == 1 )
				NMStimStatsUpdate()
			endif
			
			ClampGraphsCopy( -1, 1 )
			
			NMStimSaveList( ask, new, slist )
		
			break
			
		case "Close":
		case "Kill":
		
			DoAlert 1, "Are you sure you want to close " + currentStim + "?"
			
			if ( V_flag != 1 )
				break
			endif
			
			slist = RemoveFromList( currentStim, slist )
			
			if ( strlen( CurrentStim ) == 0 )
				break
			endif
			
			if ( NMStimClose( currentStim ) == -1 )
				break
			endif
				
			if ( ItemsInList( slist ) > 0 )
				StimCurrentSet( StringFromList( 0,slist ) ) // set to new stim
			else
				ClampTabUpdate()
			endif
			
			break
			
		case "Close All":
		case "Kill All":
		
			if ( ItemsInList( slist ) == 0 )
				break
			endif
		
			DoAlert 1, "Are you sure you want to close all stimulus protocols?"
			
			if ( V_flag != 1 )
				break
			endif
			
			NMStimClose( slist )
			
			ClampTabUpdate()
			
			break
			
		case "Copy":
		
			if ( stimexists == 0 )
				break
			endif
			
			sname = currentStim + "_copy"
			
			Prompt sname, "new stimulus name:"
			DoPrompt "Copy Stimulus Protocol", sname
			
			if ( V_flag == 1 )
				break // cancel
			endif
			
			NMStimCopy( currentStim, sname )
			StimCurrentSet( sname )
			
			break
			
		case "Rename":
		
			if ( stimexists == 0 )
				break
			endif
			
			sname = currentStim
			
			Prompt sname, "rename stimulus as:"
			DoPrompt "Rename Stimulus Protocol", sname
			
			if ( ( V_flag == 1 ) || ( strlen( sname ) == 0 ) || ( StringMatch( sname, currentStim ) == 1 ) )
				break // cancel
			endif
			
			sname = NMFolderNameCreate( sname )
			
			if ( NMStimRename( currentStim, sname ) == 0 )
				StimCurrentSet( sname )
			endif
			
			break
			
		case "Retrieve":
		
			gdf = GetDataFolder( 1 )
			
			if ( ItemsInList( slist ) == 0 )
				DoAlert 0, "No Stim folder located in current data folder " + NMQuotes( GetDataFolder( 0 ) )
				break
			endif
			
			Prompt sname, "open:", popup slist
			DoPrompt "Retrieve Stimulus Protocol : " + gdf, sname
			
			if ( V_flag == 1 )
				break // cancel
			endif
			
			newName = CheckFolderName( dp+sname )
			
			DuplicateDataFolder $gdf + sname, $newName
			SetNMvar( newName+":StatsOn", 0 ) // make sure stats is OFF when retrieving
			StimCurrentSet( NMChild( newName ) )
			StimWavesCheck( StimDF(), 0 )
			
			break
			
		case "Set Stim Path":
			ClampStimPathAsk()
			break
			
		case "Set Stim List":
			ClampStimListAsk()
			break
			
		default: // should be a stim
		
			if ( WhichListItem( select, slist, ";", 0, 0 ) >= 0 )
				ClampGraphsCopy( -1, 1 ) // save Chan graphs configs before changing
				StimCurrentSet( select )
			else
				
			endif
			
	endswitch
	
	StimWavesCheck( StimDF(), 0 )
	
	UpdateNMPanel( 0 )
	ClampTabUpdate()
	ChanGraphsUpdate()
	ClampGraphsCloseUnecessary()
	
	PulseGraph( 0 )
	PulseTableManager( 0 )
	
End // StimCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StimListPopup( ctrlName, popNum, popstr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popstr
	
	ClampError( 0, "" )
	
	StimCall( popstr )
	
	//ClampTabUpdate()
	
End // StimListPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ClampError( 0, "" )
	
	ctrlName = ctrlName[ 4, inf ]

	strswitch( ctrlName )
	
		case "StartPreview":
			ClampAcquireCall( 0 )
			break
			
		case "StartRecord":
			ClampAcquireCall( 1 )
			break
		
		case "Note":
			NMNotesAddNote( "" )
			break
			
		//case "TGain":
		//	ClampTGainConfigCall()
		//	break
			
	endswitch

End // ClampButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	strswitch( ctrlName )
	
		case "DemoMode":
			ClampDemoModeSet( checked )
			ClampTabUpdate()
			break
	
	endswitch
	
End // NMClampTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampButtonDisable( mode )
	Variable mode // ( 0 ) preview ( 1 ) record ( -1 ) nothing
	String pf = "", rf = ""

	switch ( mode )
		case 0:
			pf = "\\K( 65280,0,0 )"
			break
		case 1:
			rf = "\\K( 65280,0,0 )"
			break
	endswitch
	
	Button CT0_StartPreview, win=$NMPanelName, title=pf+"Preview"
	Button CT0_StartRecord, win=$NMPanelName, title=rf+"Record"

End // ClampButtonDisable

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabControl( name, tab )
	String name; Variable tab
	
	ClampTabChange( tab )

End // ClampTabControl

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabChange( tab )
	Variable tab
	
	Variable lastTab = NumVarOrDefault( NMClampTabDF + "CurrentTab", 0 )
	
	String CurrentStim = StimCurrent()
	
	ClampError( 0, "" )
	
	SetNMvar( NMClampTabDF + "CurrentTab", tab )
	ChangeTab( lastTab, tab, StrVarOrDefault( NMClampTabDF + "TabControlList", "" ) ) // NM_TabManager.ipf
	
	if ( tab == 2 ) // Pulse
		DoWindow /F $NMPulseGraphName
		DoWindow /F PG_StimTable
	endif
	
End // ClampTabChange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampTabName() // return current tab name

	Variable tabnum = NumVarOrDefault( NMClampTabDF + "CurrentTab", 0 )
	
	return TabName( tabnum, StrVarOrDefault( NMClampTabDF + "TabControlList", "" ) )

End // ClampTabName

//****************************************************************
//****************************************************************
//****************************************************************
//
//	File tab control functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function FileTab( enable ) // NM Clamp configure tab enable
	Variable enable
	
	String str, sdf = StimDF()
	
	if ( enable == 1 )
		
		SetNMstr( NMClampTabDF + "StimTag", StrVarOrDefault( sdf + "StimTag", "" ) )
		
		// folder and file details
		
		GroupBox CT1_DataGrp, win=$NMPanelName, title="Folder : "+GetDataFolder( 0 )
		
		PathInfo /S ClampPath

		if ( strlen( S_path ) > 0 )
			SetNMstr( NMClampDF + "ClampPath", S_path )
		endif
		
		Variable saveFormat = NumVarOrDefault( NMClampDF + "SaveFormat", 2 )
		Variable saveWhen = NumVarOrDefault( NMClampDF + "SaveWhen", 1 )
		
		str = "save"
		
		switch( saveFormat )
			case 1:
				str += " ( NM"
				break
			case 2:
				str += " ( Igor"
				break
			case 3:
				str += " ( NM,Igor"
				break
			case 4:
				str += " ( HDF5"
				break
		endswitch
		
		switch( saveWhen )
			default:
				str = "save"
				break
			case 1:
				str += ";after )"
				break
			case 2:
				str += ";while )"
				saveWhen = 1
				break
		endswitch
		
		Checkbox CT1_SaveConfig, win=$NMPanelName, value=( saveWhen ), title=str
		Checkbox CT1_CloseFolder, win=$NMPanelName, value=NumVarOrDefault( NMClampDF + "AutoCloseFolder", 1 )
		Checkbox CT1_LogAutoSave, win=$NMPanelName, value=( NumVarOrDefault( NMClampDF + "LogAutoSave", 1 ) )
		
		Variable logdsply = NumVarOrDefault( NMClampDF + "LogDisplay", 1 )
		
		PopupMenu CT1_LogMenu, win=$NMPanelName, mode=( logdsply+3 )
		
		//PulseGraph( 0 )
	
	endif

End // FileTab

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	FileTabCall( ctrlName, checked, "" )
	
End // FileTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ctrlName[ 4, inf ]
	
	FileTabCall( ctrlName, varNum, varStr )
	
End // FileTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabPopup( ctrlName, popNum, popstr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popstr
	
	ctrlName = ctrlName[ 4, inf ]
	
	FileTabCall( ctrlName, popNum, popstr )
	
End // FileTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ctrlName[ 4, inf ]
	
	FileTabCall( ctrlName, Nan, "" )
	
End // FileTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function FileTabCall( select, varNum, varStr )
	String select
	Variable varNum
	String varStr
	
	ClampError( 0, "" )
	
	strswitch( select )
	
		case "SaveConfig":
			ClampSaveAsk()
			break
			
		case "CloseFolder":
			ClampFolderAutoCloseSet( varNum, userPrompt = 1 )
			break
			
		case "LogAutoSave":
			ClampLogAutoSaveSet( varNum )
			break
			
		case "FilePathSet":
			ClampPathSet( varStr )
			break
			
		case "FilePrefix":
			ClampFileNamePrefixSet( varStr )
			break
			
		case "StimSuffix":
			NMStimTagSet( "", varStr )
			break
			
		case "FileCellSet":
			if ( numtype( varNum ) == 0 )
				ClampDataFolderSeqReset()
			endif
			break
			
		case "FileNewCell":
			ClampDataFolderNewCell()
			break
			
		case "UserName":
		case "UserLab":
		case "ExpTitle":
			if ( WinType( NMNotesTableName ) == 2 )
				NMNotesTable( 0 ) // update Notes table
			endif
			break
			
		case "NotesEdit":
			NMNotesTable2Vars() // update note values
			NMNotesTable( 0 )
			DoWindow /F $NMNotesTableName
			break
			
		case "LogMenu":
			ClampLogDisplaySet( varStr )
			break
			
	endswitch
	
	FileTab( 1 )
	
End // FileTabCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim tab control functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function StimTab( enable )
	Variable enable
	
	Variable misc, tim, insouts, pulse
	
	Variable chain = NMStimChainOn( "" )
	String select = StimTabMode()
	
	if ( enable == 1 )
	
		strswitch( select )
			case "Misc":
				misc = 1
				Checkbox CT2_MiscCheck, win=$NMPanelName, value=1, title="\f01Misc"
				Checkbox CT2_TimeCheck, win=$NMPanelName, value=0, title="Time"
				Checkbox CT2_Boardcheck, win=$NMPanelName, value=0, title="Ins / Outs"
				Checkbox CT2_Pulsecheck, win=$NMPanelName, value=0, title="Pulse"
				break
			case "Time":
				tim = 1
				Checkbox CT2_MiscCheck, win=$NMPanelName, value=0, title="Misc"
				Checkbox CT2_TimeCheck, win=$NMPanelName, value=1, title="\f01Time"
				Checkbox CT2_Boardcheck, win=$NMPanelName, value=0, title="Ins / Outs"
				Checkbox CT2_Pulsecheck, win=$NMPanelName, value=0, title="Pulse"
				break
			case "Ins/Outs":
				insouts = 1
				Checkbox CT2_MiscCheck, win=$NMPanelName, value=0, title="Misc"
				Checkbox CT2_TimeCheck, win=$NMPanelName, value=0, title="Time"
				Checkbox CT2_Boardcheck, win=$NMPanelName, value=1, title="\f01Ins / Outs"
				Checkbox CT2_Pulsecheck, win=$NMPanelName, value=0, title="Pulse"
				break
			case "Pulse":
				pulse = 1
				Checkbox CT2_MiscCheck, win=$NMPanelName, value=0, title="Misc"
				Checkbox CT2_TimeCheck, win=$NMPanelName, value=0, title="Time"
				Checkbox CT2_Boardcheck, win=$NMPanelName, value=0, title="Ins / Outs"
				Checkbox CT2_Pulsecheck, win=$NMPanelName, value=1, title="\f01Pulse"
		endswitch
		
		if ( chain == 1 )
			tim = 0
			insouts = 0
			pulse = 0
		endif
		
		NMStimBoardConfigsUpdateAll( "" )
		
		StimTabMisc( misc )
		StimTabTime( tim )
		StimTabBoard( insouts )
		StimTabPulse( pulse )
		
		if ( chain == 1 )
			Checkbox CT2_ChainCheck, win=$NMPanelName, disable=0, value=1
		endif
		
	endif

End // StimTab

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabMisc( enable )
	Variable enable
	
	Variable chain = NMStimChainOn( "" )
	//Variable pn = ClampPN()
	String pnstr, sdf = StimDF()
		
	SetNMstr( NMClampTabDF + "StimTag", StrVarOrDefault( sdf + "StimTag", "" ) )
	SetNMstr( NMClampTabDF + "DataPrefix", StrVarOrDefault( sdf + "WavePrefix", "" ) )
	SetNMstr( NMClampTabDF + "PreStimFxnList", StrVarOrDefault( sdf + "PreStimFxnList", "" ) )
	SetNMstr( NMClampTabDF + "InterStimFxnList", StrVarOrDefault( sdf + "InterStimFxnList", "" ) )
	SetNMstr( NMClampTabDF + "PostStimFxnList", StrVarOrDefault( sdf + "PostStimFxnList", "" ) )
	
	Checkbox CT2_ChainCheck, win=$NMPanelName, disable=!enable, value=chain
		
	if ( chain == 1 )
		enable = 0
	endif
	
	//if ( pn == 0 )
	//	pnstr = "P / N"
	//else
	//	pnstr = "P / " + num2istr( pn )
	//endif
	
	Checkbox CT2_StatsCheck, win=$NMPanelName, disable=!enable, value=NMStimStatsOn()
	Checkbox CT2_SpikeCheck, win=$NMPanelName, disable=!enable, value=NMStimSpikeOn()
	//Checkbox CT2_PNCheck, win=$NMPanelName, disable=!enable, value=pn, title=pnstr
	SetVariable CT2_ADCprefix, win=$NMPanelName, disable=!enable
	SetVariable CT2_StimSuffix, win=$NMPanelName, disable=!enable
	PopupMenu CT2_MacroBefore, win=$NMPanelName, disable=!enable, mode=1, value="before;---;"+StrVarOrDefault( StimDF()+"PreStimFxnList", "" )+"---;Add to List;Remove from List;Clear List;"
	PopupMenu CT2_MacroDuring, win=$NMPanelName, disable=!enable, mode=1, value="during;---;"+StrVarOrDefault( StimDF()+"InterStimFxnList", "" )+"---;Add to List;Remove from List;Clear List;"
	PopupMenu CT2_MacroAfter, win=$NMPanelName, disable=!enable, mode=1, value="after;---;"+StrVarOrDefault( StimDF()+"PostStimFxnList", "" )+"---;Add to List;Remove from List;Clear List;"
	SetVariable CT2_MacroBeforeList, win=$NMPanelName, disable=!enable
	SetVariable CT2_MacroDuringList, win=$NMPanelName, disable=!enable
	SetVariable CT2_MacroAfterList, win=$NMPanelName, disable=!enable
	
End // StimTabMisc

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabTime( enable )
	Variable enable
	
	Variable dis, tempvar, driver, slave
	String sdf = StimDF()
	String alist = NMStimAcqModeList()
	
	NMStimTauCheck( sdf ) // check/update timing variables
	
	Variable amode = NumVarOrDefault( sdf + "AcqMode", NaN )

	SetNMvar( NMClampTabDF + "NumStimWaves", NumVarOrDefault( sdf + "NumStimWaves", NaN ) )
	SetNMvar( NMClampTabDF + "WaveLength", NumVarOrDefault( sdf + "WaveLength", NaN ) )
	
	SetNMvar( NMClampTabDF + "SampleInterval", NumVarOrDefault( sdf + "SampleInterval", NaN ) )
	SetNMvar( NMClampTabDF + "SamplesPerWave", NumVarOrDefault( sdf + "SamplesPerWave", NaN ) )
	
	SetNMvar( NMClampTabDF + "InterStimTime", NumVarOrDefault( sdf + "InterStimTime", NaN ) )
	SetNMvar( NMClampTabDF + "StimRate", NumVarOrDefault( sdf + "StimRate", NaN ) )
	
	SetNMvar( NMClampTabDF + "NumStimReps", NumVarOrDefault( sdf + "NumStimReps", NaN ) )
	SetNMvar( NMClampTabDF + "TotalTime", NumVarOrDefault( sdf + "TotalTime", NaN ) )
	
	SetNMvar( NMClampTabDF + "InterRepTime", NumVarOrDefault( sdf + "InterRepTime", NaN ) )
	SetNMvar( NMClampTabDF + "RepRate", NumVarOrDefault( sdf + "RepRate", NaN ) )
	
	// acquisition mode popup
	
	switch( amode )
		case 0:
			amode = 1 + WhichListItem( "epic precise", alist, ";", 0, 0 )
			break
		case 1:
			amode = 1 + WhichListItem( "continuous", alist, ";", 0, 0 )
			dis = 1
			break
		case 2:
			amode = 1 + WhichListItem( "episodic", alist, ";", 0, 0 )
			break
		case 3:
			amode = 1 + WhichListItem( "epic triggered", alist, ";", 0, 0 )
			break
		case 4:
			amode = 1 + WhichListItem( "continuous triggered", alist, ";", 0, 0 )
			dis = 1
			break
	endswitch
	
	PopupMenu CT2_AcqMode, win=$NMPanelName, value=NMStimAcqModeList(), mode=amode, disable=!enable
		
	// acq board popup
	
	//tempvar = NumVarOrDefault( NMClampTabDF + "CurrentBoard", 0 )
	//driver = NumVarOrDefault( NMClampDF + "BoardDriver", 0 )

	//if ( tempvar == 0 ) // nothing selected
	//	tempvar = driver
	//endif
	
	//if ( tempvar != driver )
	//	slave = 1
	//endif
	
	//if ( tempvar == 0 )
		//tempvar = 1
	//endif
	
	//PopupMenu CT2_TauBoard, win=$NMPanelName, mode=( tempvar ), value=StrVarOrDefault( NMClampDF+"BoardList", "" ), disable=!enable
	
	if ( NMStimDACUpSamplingOK() )
		
		PopupMenu CT2_TauDAC, win=$NMPanelName, mode=1, value=StimTabTimeDACdtList(), disable=!enable
		
	else
	
		PopupMenu CT2_TauDAC, win=$NMPanelName, mode=1, value="", disable=1
		
	endif
	
	GroupBox CT2_WaveGrp, win=$NMPanelName, disable=!enable
	SetVariable CT2_NumStimWaves, win=$NMPanelName, disable=!enable
	SetVariable CT2_WaveLength, win=$NMPanelName, disable=!enable
	SetVariable CT2_SampleInterval, win=$NMPanelName, disable=!enable
	SetVariable CT2_SamplesPerWave, win=$NMPanelName, disable=!enable
	SetVariable CT2_InterStimTime, win=$NMPanelName, disable=(!enable || dis)
	SetVariable CT2_StimRate, win=$NMPanelName, disable=!enable
	
	GroupBox CT2_RepGrp, win=$NMPanelName, disable=!enable
	SetVariable CT2_NumStimReps, win=$NMPanelName, disable=!enable
	SetVariable CT2_TotalTime, win=$NMPanelName, disable=(!enable || dis)
	SetVariable CT2_InterRepTime, win=$NMPanelName, disable=(!enable || dis)
	SetVariable CT2_RepRate, win=$NMPanelName, disable=!enable
	
End // StimTabTime

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTabTimeDACdtList()

	Variable sInterval, intvl
	String sdf = StimDF()
	
	Variable upsamples = round( NumVarOrDefault( sdf + "DACUpsamples", 1 ) )
	
	if ( ( numtype( upsamples ) > 0 ) || ( upsamples <= 1 ) )
		return "DAC dt;upsample;" // no upsampling
	endif
	
	sInterval = NumVarOrDefault( sdf + "SampleInterval", NaN )
	intvl = sInterval / upsamples

	return "DAC dt=" + num2str( intvl ) + ";upsample=" + num2istr( upsamples ) + ";"

End // StimTabTimeDACdtList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabBoard( enable )
	Variable enable
	
	GroupBox CT2_ADCgrp, win=$NMPanelName, disable=!enable
	GroupBox CT2_DACgrp, win=$NMPanelName, disable=!enable
	GroupBox CT2_TTLgrp, win=$NMPanelName, disable=!enable
	
	PopupMenu $"CT2_ADC0", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "ADC", 0 ), value=StimTabIOList( "ADC", 0 )
	PopupMenu $"CT2_ADC1", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "ADC", 1 ), value=StimTabIOList( "ADC", 1 )
	PopupMenu $"CT2_ADC2", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "ADC", 2 ), value=StimTabIOList( "ADC", 2 )
	PopupMenu $"CT2_ADC3", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "ADC", 3 ), value=StimTabIOList( "ADC", 3 )
	PopupMenu $"CT2_ADC4", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "ADC", 4 ), value=StimTabIOList( "ADC", 4 )
	PopupMenu $"CT2_ADC5", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "ADC", 5 ), value=StimTabIOList( "ADC", 5 )
	PopupMenu $"CT2_ADC6", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "ADC", 6 ), value=StimTabIOList( "ADC", 6 )
	//PopupMenu $"CT2_ADC7", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "ADC", 7 ), value=StimTabIOList( "ADC", 7 )
	
	PopupMenu $"CT2_DAC0", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "DAC", 0 ), value=StimTabIOList( "DAC", 0 )
	PopupMenu $"CT2_DAC1", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "DAC", 1 ), value=StimTabIOList( "DAC", 1 )
	PopupMenu $"CT2_DAC2", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "DAC", 2 ), value=StimTabIOList( "DAC", 2 )
	PopupMenu $"CT2_DAC3", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "DAC", 3 ), value=StimTabIOList( "DAC", 3 )
	PopupMenu $"CT2_DAC4", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "DAC", 4 ), value=StimTabIOList( "DAC", 4 )
	PopupMenu $"CT2_DAC5", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "DAC", 5 ), value=StimTabIOList( "DAC", 5 )
	PopupMenu $"CT2_DAC6", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "DAC", 6 ), value=StimTabIOList( "DAC", 6 )
	//PopupMenu $"CT2_DAC7", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "DAC", 7 ), value=StimTabIOList( "DAC", 7 )
	
	PopupMenu $"CT2_TTL0", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "TTL", 0 ), value=StimTabIOList( "TTL", 0 )
	PopupMenu $"CT2_TTL1", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "TTL", 1 ), value=StimTabIOList( "TTL", 1 )
	PopupMenu $"CT2_TTL2", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "TTL", 2 ), value=StimTabIOList( "TTL", 2 )
	PopupMenu $"CT2_TTL3", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "TTL", 3 ), value=StimTabIOList( "TTL", 3 )
	PopupMenu $"CT2_TTL4", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "TTL", 4 ), value=StimTabIOList( "TTL", 4 )
	PopupMenu $"CT2_TTL5", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "TTL", 5 ), value=StimTabIOList( "TTL", 5 )
	PopupMenu $"CT2_TTL6", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "TTL", 6 ), value=StimTabIOList( "TTL", 6 )
	//PopupMenu $"CT2_TTL7", win=$NMPanelName, disable=!enable, mode=StimTabIOMode( "TTL", 7 ), value=StimTabIOList( "TTL", 7 )
	
	Button CT2_IOtable, win=$NMPanelName, disable=!enable
	//Button CT2_Tab, win=$NMPanelName, disable=!enable
	
	Checkbox CT2_GlobalConfigs, value=NMStimUseGlobalBoardConfigs( "" ), disable=!enable
	
End // StimTabBoard

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabPulse( enable )
	Variable enable
	
	Variable md
	String wlist
	String sdf = StimDF()
	String gname = NMPulseGraphName
	
	String pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	
	STRUCT NMPulseLBWaves lb
	
	wlist = StimPrefixListAll( sdf )
	
	if ( WhichListItem( pPrefix, wlist, ";", 0, 0 ) == -1 )
		pPrefix = ""
	endif

	if ( ( strlen( pPrefix ) == 0 ) && ( strlen( wlist ) > 0 ) )
		pPrefix = StringFromList( 0, wlist )
		SetNMstr( NMClampTabDF + "PulsePrefix", pPrefix )
		pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	endif
	
	if ( strlen( wlist ) == 0 )
		pPrefix = ""
		SetNMstr( NMClampTabDF + "PulsePrefix", pPrefix )
		PopupMenu CT2_WavePrefix, win=$NMPanelName, mode=1, value="no outputs;", disable=!enable
	else
		md = WhichListItem( pPrefix, wlist, ";", 0, 0 ) + 1
		PopupMenu CT2_WavePrefix, win=$NMPanelName, mode=md, value=StimNameListAll( StimDF() ), disable=!enable
	endif
	
	Button CT2_Display, win=$NMPanelName, disable=!enable
	
	PulseConfigsCheck()
	
	Listbox CT2_PulseConfigs, win=$NMPanelName, disable=!enable
	Listbox CT2_PulseParams, win=$NMPanelName, disable=!enable
	
	NMClampPulseLBWavesDefault( lb )
	
	NMPulseLB1Update( lb )
	NMPulseLB2Update( lb )

	Checkbox CT2_UseMyWaves, win=$NMPanelName, value=NumVarOrDefault( sdf + "PulseGenOff", 0 ), disable=!enable
	
	PulseGraph( 0 )
	
	if ( enable == 1 )
	
		PulseTableManager( 0 )
		
		if ( WinType( gname ) == 1 )
			DoWindow /F $gname
		endif
	
	endif
	
End // StimTabPulse

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTabMode()

	return StrVarOrDefault( NMClampTabDF+"StimTabMode", "Time" )

End // StimTabMode

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimTabIOList( io, config )
	String io
	Variable config

	Variable icnt
	String ioname
	
	String slist = " ;"
	String ludf = NMStimBoardLookUpDF( "" )
	String bdf = NMStimBoardDF( "" )
	
	if ( ( WaveExists( $bdf + io + "name" ) == 0 ) || ( WaveExists( $ludf + io + "name" ) == 0 ) )
		return "None"
	endif
	
	Wave /T IOnameS = $bdf + io + "name"
	Wave /T IOnameL = $ludf + io + "name"
	
	for ( icnt = 0; icnt < numpnts( IOnameL ); icnt += 1 )
		ioname = IOnameL[icnt]
		slist = AddListItem( ioname, slist, ";", inf )
	endfor
	
	for ( icnt = 0; icnt < numpnts( IOnameS ); icnt += 1 )
	
		if ( icnt == config )
			continue
		endif
		
		ioname = IOnameS[icnt]
		
		if ( strlen( ioname ) > 0 )
			slist = RemoveFromList( ioname, slist )
		endif
		
	endfor
	
	if ( StringMatch( io, "ADC" ) == 1 )
		slist += ClampTGainConfigNameList()
	endif
	
	slist = AddListItem( "ERROR", slist, ";", inf )
	
	return slist

End // StimTabIOList

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabIOMode( io, config )
	String io
	Variable config
	
	Variable mode = 1
	String configName
	
	String bdf = NMStimBoardDF( StimDF() )
	String mlist = StimTabIOList( io, config )
	
	if ( ( WaveExists( $bdf+io+"name" ) == 0 ) || ( ItemsInList( mlist ) == 0 ) )
		return 1
	endif
	
	Wave /T name = $bdf + io + "name"
	
	if ( ( config < 0 ) || ( config >= numpnts( name ) ) )
		return 1
	endif
	
	configName = name[config]
	
	if ( strlen( configName ) > 0 )
	
		mode = WhichListItem( configName, mlist, ";", 0, 0 )
		
		if ( ( mode < 0 ) && ( StringMatch( configName[0,5], "TGain_" ) == 0 ) )
			mode = 1 + WhichListItem( "ERROR", mlist, ";", 0, 0 )
			ClampError( 0, "failed to find config " + NMQuotes( configName ) + ". Please reselect " + io + " config #" + num2istr( config ) )
		else
			mode += 1
		endif
			
	endif
	
	return max( mode, 1 )
	
End // StimTabIOMode

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabCall( select, varNum, varStr )
	String select
	Variable varNum
	String varStr
	
	ClampError( 0, "" )
	
	String sdf = StimDF()
	
	strswitch( select )
	
		case "MiscCheck":
			SetNMstr( NMClampTabDF + "StimTabMode", "Misc" )
			break
			
		case "TimeCheck":
			SetNMstr( NMClampTabDF + "StimTabMode", "Time" )
			break
			
		case "BoardCheck":
			SetNMstr( NMClampTabDF + "StimTabMode", "Ins/Outs" )
			break
			
		case "PulseCheck":
			SetNMstr( NMClampTabDF + "StimTabMode", "Pulse" )
			break
	
		case "ChainCheck":
			NMStimChainSet( "", varNum )
			ClampTabUpdate()
			return 0
			
		case "StatsCheck":
			return NMStimStatsOnSet( varNum )
			
		case "SpikeCheck":
			return NMStimSpikeCall( varNum )
			
		//case "PNCheck":
			//return ClampPNenable( varNum )
			
		case "ADCprefix":
			NMStimWavePrefixSet( "", varStr )
			break
			
		case "StimSuffix":
			NMStimTagSet( "", varStr )
			break
			
		case "PreAnalysisList":
			NMStimFxnListSet( "", "Before", varStr )
			break
		
		case "InterAnalysisList":
			NMStimFxnListSet( "", "During", varStr )
			break
			
		case "PostAnalysisList":
			NMStimFxnListSet( "", "After", varStr )
			break
			
		case "AcqMode":
			NMStimAcqModeSet( "", varStr )
			StimWavesCheck( sdf, 1 )
			//StimTabTauCheck()
			break
			
		case "TauDAC":
			if ( strsearch( varStr, "upsample", 0 ) >= 0 )
				NMStimDACUpSamplingCall( sdf )
			endif
			break
			
		//case "TauBoard":
			//SetNMvar( NMClampTabDF + "CurrentBoard", varNum )
			//break
			
		case "GlobalConfigs":
			NMStimUseGlobalBoardConfigsSet( "", varNum )
			break
			
		case "IOtable":
			StimIOtable()
			break
	
	endswitch
	
	StimTab( 1 )
	
End // StimTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ctrlName[ 4, inf ]
	
	return StimTabCall( ctrlName, Nan, "" )
	
End // StimTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	StimTabCall( ctrlName, checked, "" )
	
End // StimTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ctrlName[ 4, inf ]
	
	StimTabCall( ctrlName, varNum, varStr )
	
End // StimTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabPopup( ctrlName, popNum, popstr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popstr
	
	ctrlName = ctrlName[ 4, inf ]
	
	StimTabCall( ctrlName, popNum, popstr )
	
End // StimTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabFxnPopup( ctrlName, popNum, popstr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popstr
	
	String select = ReplaceString( "CT2_Macro", ctrlName, "" )
	
	ClampError( 0, "" )
	
	strswitch( select )
		case "Before":
		case "During":
		case "After":
			break
		default:
			return -1
	endswitch
	
	strswitch( popstr )
	
		case "Add to List":
			NMStimFxnListAddAsk( "", select )
			break
			
		case "Remove from List":
			NMStimFxnListRemoveAsk( "", select )
			break
			
		case "Clear List":
			NMStimFxnListClear( "", select )
			break
			
		default:
			if ( exists( popstr ) == 6 )
				Execute /Z popstr + "(1)" // call function's with config flag 1
			endif
			
	endswitch
	
	StimTab( 1 )
	
End // StimTabFxnPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabSetTau( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ClampError( 0, "" )
	
	Variable nStimWaves, wLength, intvl, interStimT, interRepT 
	Variable pulseUpdate = 1, updateNM = 0
	String sdf = StimDF()

	strswitch( ctrlName[4,inf] )
	
		case "NumStimWaves":
		
			updateNM = 1
			
			if ( ( numtype( varNum ) == 0 ) && ( varNum > 0 ) )
				SetNMvar( sdf + "NumStimWaves", round( varNum ) )
			endif
			
			break
			
		case "WaveLength":
		
			if ( ( numtype( varNum ) == 0 ) && ( varNum > 0 ) )
				SetNMvar( sdf + "WaveLength", varNum )
			endif
			
			break
	
		case "SampleInterval":
		
			if ( ( numtype( varNum ) == 0 ) && ( varNum > 0 ) )
				NMStimIntervalSet( sdf, varNum )
			endif
			
			break
		
		case "SamplesPerWave":
		
			// must change WaveLength instead of SamplesPerWave
		
			if ( ( numtype( varNum ) == 0 ) && ( varNum > 0 ) )
			
				intvl = NumVarOrDefault( sdf + "SampleInterval", NaN )
				wLength = round( varNum ) * intvl
				
				if ( ( numtype( wLength ) == 0 ) && ( wLength > 0 ) )
					SetNMvar( sdf + "WaveLength", wLength ) 
				endif
					
			endif
			
			break
			
		case "InterStimTime":
		
			pulseUpdate = 0
		
			if ( ( numtype( varNum ) == 0 ) && ( varNum >= 0 ) )
				SetNMvar( sdf + "InterStimTime", varNum )
			endif
			
			break
		
		case "StimRate":
		
			// must change InterStimTime instead of StimRate
		
			pulseUpdate = 0
			
			if ( ( numtype( varNum ) == 0 ) && ( varNum > 0 ) )
			
				wLength = NumVarOrDefault( sdf + "WaveLength", NaN )
				interStimT = ( 1000 / varNum ) - wLength // ms
				
				if ( ( numtype( interStimT ) == 0 ) && ( interStimT > 0 ) )
					SetNMvar( sdf + "InterStimTime", interStimT )
				endif
			
			endif
			
			break
			
		case "NumStimReps":
		
			pulseUpdate = 0
			
			if ( ( numtype( varNum ) == 0 ) && ( varNum > 0 ) )
				SetNMvar( sdf + "NumStimReps", round( varNum ) )
			endif
			
			break
			
		case "InterRepTime":
		
			pulseUpdate = 0
			
			if ( ( numtype( varNum ) == 0 ) && ( varNum >= 0 ) )
				SetNMvar( sdf + "InterRepTime", varNum )
			endif
			
			
			break
			
		case "RepRate":
		
			// must change InterRepTime instead of RepRate
		
			pulseUpdate = 0
			
			if ( ( numtype( varNum ) == 0 ) && ( varNum > 0 ) )
				
				nStimWaves = NumVarOrDefault( sdf + "NumStimWaves", NaN )
				wLength = NumVarOrDefault( sdf + "WaveLength", NaN )
				interStimT = NumVarOrDefault( sdf + "InterStimTime", NaN )
				
				interRepT = ( 1000 / varNum ) - nStimWaves * ( wLength + interStimT )
				
				if ( ( numtype( interRepT ) == 0 ) && ( interRepT >= 0 ) )
					SetNMvar( sdf + "InterRepTime", interRepT )
				endif
			
			endif
			
			break
			
	endswitch
	
	//StimTabTauCheck()
	
	if ( pulseUpdate )
		StimWavesCheck( sdf, 1 )
		PulseGraph( 0 )
	endif
	
	if ( updateNM )
		UpdateNMPanel( 0 )
	else
		StimTab( 1 )
	endif
	
End // StimTabSetTau

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabTauCheck_DEPRECATED() // see NMStimTauCheck, called via StimTabTime

	String varName
	String sdf = StimDF()
	
	Variable acqMode = NMStimAcqMode( sdf )
	
	Variable NumStimWaves = NumVarOrDefault( NMClampTabDF + "NumStimWaves", 1 )
	Variable WaveLength = NumVarOrDefault( NMClampTabDF + "WaveLength", NMStimWaveLength )
	
	Variable SampleInterval = NumVarOrDefault( NMClampTabDF + "SampleInterval", 0.1 )
	Variable SamplesPerWave = NumVarOrDefault( NMClampTabDF + "SamplesPerWave", 1 )
	
	Variable InterStimTime = NumVarOrDefault( NMClampTabDF + "InterStimTime", 0 )
	Variable StimRate = NumVarOrDefault( NMClampTabDF + "StimRate", 0 )
	
	Variable NumStimReps = NumVarOrDefault( NMClampTabDF + "NumStimReps", 1 )
	
	Variable InterRepTime = NumVarOrDefault( NMClampTabDF + "InterRepTime", 0 )
	Variable RepRate = NumVarOrDefault( NMClampTabDF + "RepRate", 0 )
	
	Variable CurrentBoard = NumVarOrDefault( NMClampTabDF + "CurrentBoard", 0 )
	Variable BoardDriver = NumVarOrDefault( NMClampTabDF + "BoardDriver", 0 )
	
	String AcqBoard = StrVarOrDefault( NMClampDF + "AcqBoard", "" )
	
	switch( AcqMode )
	
		case 0: // epic precise
		case 2: // episodic
		case 3: // episodic triggered
		
			if ( InterStimTime == 0 )
				InterStimTime = 500
				ClampError( 1, "zero wave interlude time not allowed with episodic acquisition." )
			endif
			
			StimRate = 1000 / ( WaveLength + InterStimTime )
			RepRate = 1000 / ( InterRepTime + NumStimWaves * ( WaveLength + InterStimTime ) )
			
			break
			
		case 1: // continuous
		case 4: // continuous triggered
		
			if ( ( StringMatch( AcqBoard, "NIDAQ" ) == 1 ) && ( NumStimWaves > 1 ) )
				NumStimWaves = 1
				ClampError( 1, "only one stimulus wave is allowed with continuous acquisition." )
			endif
			
			StimRate = 1000 / WaveLength
			RepRate = 1000 / ( NumStimWaves * WaveLength )
	
	endswitch
	
	SamplesPerWave = floor( WaveLength / SampleInterval )

	SetNMvar( sdf + "NumStimWaves", NumStimWaves )
	SetNMvar( "NumGrps", NumStimWaves )
	SetNMvar( sdf + "WaveLength", WaveLength )
	
	SetNMvar( sdf + "SamplesPerWave", SamplesPerWave )
	
	SetNMvar( sdf + "InterStimTime", InterStimTime )
	SetNMvar( sdf + "StimRate", StimRate )
	
	SetNMvar( sdf + "NumStimReps", NumStimReps )
	
	SetNMvar( sdf + "InterRepTime", InterRepTime )
	SetNMvar( sdf + "RepRate", RepRate )

End // StimTabTauCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function StimTabIOPopup( ctrlName, popNum, popstr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popstr
	
	Variable config, boardConfig, board, chan
	String io, tgain, oldName
	
	String tlist = ClampTGainConfigNameList()
	
	ClampError( 0, "" )
	
	ctrlName = ctrlName[ 4, inf ]
	
	io = ctrlName[0,2]
	
	config = str2num( ctrlName[3,inf] )
	
	oldName = NMStimBoardConfigName( "", io, config )
	
	if ( StringMatch( popstr, oldName ) == 1 )
	
		if ( WhichListItem( popstr, tlist, ";", 0, 0 ) >= 0 )
			ClampTGainConfigEditOld( str2num( popstr[6, inf] ) )
		else
			NMStimBoardConfigEdit( "", io, popstr )
		endif
		
	else
	
		NMStimBoardConfigActivate( "", io, config, popstr )
		NMStimBoardConfigsUpdate( "", io )
		
	endif
	
	StimTab( 1 )
	
End // StimTabIOPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function StimIOtable()
	
	NMStimBoardNamesTable( "", 1 )
	
End // StimIOtable

//****************************************************************
//****************************************************************
//****************************************************************
//
//	DAQ Board tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabIOselect()
	
	return ClampIOcheck( StrVarOrDefault( NMClampTabDF+"ConfigsTabIOselect", "ADC" ) )

End // ConfigsTabIOselect

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabIOnum()

	return NumVarOrDefault( NMClampTabDF+"IOnum", 0 )

End // ConfigsTabIOnum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDAQTab( enable )
	Variable enable
	
	Variable tempvar, icnt, config, board, chan, adc
	String tempstr, titlestr, instr, varName
	
	Variable driver = NumVarOrDefault( NMClampDF + "BoardDriver", 0 )
	String blist = StrVarOrDefault( NMClampDF + "BoardList", "" )
	String io = ConfigsTabIOselect()
	Variable tabNum = TabNumber( "DAQ", StrVarOrDefault( NMClampTabDF + "TabControlList", "" ) )
	
	config = ConfigsTabIOnum()
	
	if ( strlen( io ) == 0 )
		return -1
	endif
	
	if ( ( enable == 1 ) && ( tabNum >= 0 ) )
	
		//PopupMenu CT3_InterfaceMenu, win=$NMPanelName, mode=1, value=ConfigsTabPopupList(), popvalue=StrVarOrDefault( NMClampDF+"BoardSelect", "Demo" )
		
		if ( WaveExists( $NMClampDF + io + "board" ) == 0 )
			return -1
		endif
		
		SetNMvar( NMClampTabDF + "IOnum", config )
		SetNMvar( NMClampTabDF + "IOchan", WaveValOrDefault( NMClampDF + io + "chan", config, 0 ) )
		SetNMvar( NMClampTabDF + "IOscale", WaveValOrDefault( NMClampDF + io + "scale", config, 0 ) )
		SetNMstr( NMClampTabDF + "IOname", WaveStrOrDefault( NMClampDF + io + "name", config, "" ) )
		
		strswitch( io )
			case "ADC":
				Checkbox CT3_ADCcheck, win=$NMPanelName, value=1, title="\f01ADC in"
				Checkbox CT3_DACcheck, win=$NMPanelName, value=0, title="DAC out"
				Checkbox CT3_TTLcheck, win=$NMPanelName, value=0, title="TTL out"
				break
			case "DAC":
				Checkbox CT3_ADCcheck, win=$NMPanelName, value=0, title="ADC in"
				Checkbox CT3_DACcheck, win=$NMPanelName, value=1, title="\f01DAC out"
				Checkbox CT3_TTLcheck, win=$NMPanelName, value=0, title="TTL out"
				break
			case "TTL":
				Checkbox CT3_ADCcheck, win=$NMPanelName, value=0, title="ADC in"
				Checkbox CT3_DACcheck, win=$NMPanelName, value=0, title="DAC out"
				Checkbox CT3_TTLcheck, win=$NMPanelName, value=1, title="\f01TTL out"
				break
		endswitch
		
		// buttons
		
		for ( icnt = 0; icnt < 7; icnt += 1 )
			
			titlestr = ""
			
			if ( icnt == config )
				titlestr += "\\f01"
			else
				titlestr += "\\K( 21760,21760,21760 )"
			endif
			
			titlestr += num2istr( icnt )
			
			Button $"CT3_IObnum"+num2istr( icnt ), win=$NMPanelName, title=titlestr
			
		endfor
		
		// board popup
		
		board = WaveValOrDefault( NMClampDF + io + "board", config, 0 )
		
		if ( ( numtype( board ) > 0 ) || ( board <= 0 ) ) // something wrong
			board = NumVarOrDefault( NMClampDF + "BoardDriver", 0 )
		endif
		
		tempstr = ClampBoardName( board )
		tempvar = WhichListItem( tempstr, blist, ";", 0, 0 )
		
		if ( tempvar < 0 )
			DoAlert 0, "DAQ Config Error: cannot locate board #" + num2istr( board ) + ". Please select a new board."
		endif
		
		PopupMenu CT3_IOboard, win=$NMPanelName, mode=( tempvar+1 ), value=StrVarOrDefault( NMClampDF+"BoardList", "" )
		
		// units popup
		
		tempstr = WaveStrOrDefault( NMClampDF + io + "units", config, "" )
		tempvar = WhichListItem( tempstr, StrVarOrDefault( NMClampTabDF + "UnitsList", "" ), ";", 0, 0 ) + 1
		PopupMenu CT3_IOunits, win=$NMPanelName, mode=( tempvar ), value=StrVarOrDefault( NMClampTabDF+"UnitsList", "" ) + "Other...;"
		
		// scale
		
		if ( StringMatch( io, "ADC" ) == 1 )
			titlestr = "scale ( V/" + tempstr + " ):"
		else
			titlestr = "scale ( " + tempstr + "/V ):"
		endif
		
		SetVariable CT3_IOscale, win=$NMPanelName, title=titlestr
		
		//varName = StrVarOrDefault( NMClampDF + io + "miscVarName", "" ) // NOT USED ANYMORE
		
		//if ( strlen( varName ) > 0 )
			//varName = NMClampDF + io + varName + num2str( config )
		//endif
		
		//if ( ( strlen( varName ) > 0 ) && ( exists( varName ) == 2 ) )
			
			//titlestr = StrVarOrDefault( NMClampDF + io + "miscTitle", "misc" )
			//tempstr = StrVarOrDefault( NMClampDF + io + "miscFunction", "ConfigsTabSetVariable" )
			
			//SetVariable CT3_IOmisc, win=$NMPanelName, disable=0, title=titlestr, value=$varName, proc=$tempstr
			
		//else
		
			//SetVariable CT3_IOmisc, win=$NMPanelName, disable=1
			
		//endif
		
		if ( StringMatch( io, "ADC" ) == 1 )
			
			tempvar = 0
			titlestr = WaveStrOrDefault( NMClampDF + io + "mode", config, "" )
			
			if ( strsearch( titlestr, "PreSamp=", 0, 2 ) >= 0 )
			
				tempvar = 1
				
			elseif ( strsearch( titlestr, "=", 0 ) >= 0 ) // could be a Telegraph
			
				titlestr = ClampTelegraphStrShort( titlestr )
				
				if ( strlen( titlestr ) > 0 )
					tempvar = 1 // yes, it's Telegraph
				endif
				
			endif
			
			if ( tempvar == 0 )
				titlestr = "PreSamp/TeleGrph"
			endif
			
			Checkbox CT3_ADCpresamp, win=$NMPanelName, disable=0, value=( tempvar ), title=titlestr
			
		else
		
			Checkbox CT3_ADCpresamp, win=$NMPanelName, disable=1
			
		endif
		
		strswitch( io )
			case "ADC":
				GroupBox CT3_IOgrp2, win=$NMPanelName, title = io + " Input Config " + num2istr( config )
				break
			case "DAC":
			case "TTL":
				GroupBox CT3_IOgrp2, win=$NMPanelName, title = io + " Output Config " + num2istr( config )
				break
		endswitch
		
	endif

End // ConfigsTab

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabPopupList()
	String blist = "Demo;"
	String board = StrVarOrDefault( NMClampDF+"AcqBoard", "" )
	
	if ( StringMatch( "Demo", board ) == 1 )
		return blist
	endif
	
	return AddListItem( board, blist, ";", inf )

End // ConfigsTabPopupList

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabCall( select, varNum, varStr )
	String select
	Variable varNum
	String varStr
	
	Variable saveWhat = 1
	
	Variable config = ConfigsTabIOnum()
	String io = ConfigsTabIOselect()
	
	ClampError( 0, "" )
	
	strswitch( select )
	
		case "ADCcheck":
			ConfigsTabIOset( "ADC" )
			break
			
		case "DACcheck":
			ConfigsTabIOset( "DAC" )
			break
			
		case "TTLcheck":
			ConfigsTabIOset( "TTL" )
			break
	
		case "InterfaceMenu":
			ClampBoardSet( varStr )
			break
			
		case "ADCpresamp":
			ConfigsTabPreSampAsk( varNum )
			break
			
		case "IOname":
			ClampBoardNameSet( io, config, varStr )
			break
			
		case "IOunits":
			if ( strsearch( varStr, "Other", 0, 2 ) >= 0 )
				varStr = ConfigsTabUnitsAsk()
			endif
			ClampBoardUnitsSet( io, config, varStr )
			break
			
		case "IOboard":
			ClampBoardBoardSet( io, config, varNum )
			break
			
		case "IOchan":
			ClampBoardChanSet( io, config, varNum )
			break
			
		case "IOscale":
			ClampBoardScaleSet( io, config, varNum )
			break
		
		case "IOnum":
			ConfigsTabConfigNumSet( varNum )
			break
			
		case "IOtable":
			ClampBoardTable( io, "", 1 )
			break
			
		case "IOreset":
			ConfigsTabWavesResetAsk()
			break
			
		case "IOextract":
			ConfigsTabConfigsFromStims()
			break
			
		case "IOsave":
		
			Prompt saveWhat " ", popup "save Clamp Board Configs;save Clamp Tab and Board Configs;save all NeuroMatic Configs;"
			DoPrompt "Save Configurations", saveWhat
	
			if ( V_flag == 0 )
			
				if ( saveWhat == 1 )
					ClampBoardWavesSave()
				elseif ( saveWhat == 2 )
					NMConfigSave( "Clamp" )
				else
					NMConfigSave( "All" )
				endif
				
			endif

			break
			
		default:
		
			if ( strsearch( select, "IObnum", 0, 2 ) >= 0 )
				ConfigsTabConfigNumSet( str2num( select[6, inf] ) )
			endif
	
	endswitch
	
	NMDAQTab( 1 )

End // ConfigsTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabPopup( ctrlName, popNum, popstr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popstr
	
	ctrlName = ctrlName[ 4, inf ]
	
	return ConfigsTabCall( ctrlName, popNum, popstr )
	
End // ConfigsTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ctrlName[ 4, inf ]
	
	return ConfigsTabCall( ctrlName, varNum, varStr )
	
End // ConfigsTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ctrlName[ 4, inf ]
	
	return ConfigsTabCall( ctrlName, Nan, "" )
	
End // ConfigsTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	return ConfigsTabCall( ctrlName, checked, "" )
	
End // ConfigsTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabUnitsAsk()

	String unitstr = ""
	String unitsList = StrVarOrDefault( NMClampTabDF + "UnitsList", "" )
	
	Prompt unitstr "enter channel units:"
	DoPrompt "Other Channel Units", unitstr
	
	if ( ( V_flag == 1 ) || ( strlen( unitstr ) == 0 ) )
		return ""
	endif

	if ( WhichListItem( unitstr, unitsList, ";", 0, 0 ) == -1 )
		unitstr = unitsList + unitstr + ";"
		SetNMstr( NMClampTabDF + "UnitsList", unitstr )
	endif
	
	return unitstr

End // ConfigsTabUnitsAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabIOset( io )
	String io
	
	Variable config = ConfigsTabIOnum()
	
	if ( strlen( ClampIOcheck( io ) ) == 0 )
		return -1
	endif
	
	SetNMstr( NMClampTabDF + "ConfigsTabIOselect", io )
	
	if ( config >= numpnts( $NMClampDF + io + "name" ) )
		SetNMvar( NMClampTabDF + "IOnum", 0 )
	endif
	
End // ConfigsTabIOset

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabConfigNumSet( config )
	Variable config
	
	String io = ConfigsTabIOselect()
	
	SetNMvar( NMClampTabDF+"IOnum", config )
	
	if ( config >= numpnts( $NMClampDF + io + "name" ) )
		ClampBoardWavesRedimen( io, config + 1 )
	endif
	
End // ConfigsTabConfigNumSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabWavesResetAsk()

	Variable config = ConfigsTabIOnum()
	String io = ConfigsTabIOselect()

	Variable this = NumVarOrDefault( NMClampTabDF + "ConfigsTabResetThis", 1 )
	
	Prompt this " ", popup "This " + io + " Config ( #" + num2istr( config ) + " );All " + io + " Configs;All ADC, DAC and TTL Configs;"
	DoPrompt "Reset Board Configs", this
		
	if ( V_flag == 1 )
		return 0
	endif
	
	if ( this == 2 )
		config = -1
	endif
	
	SetNMvar( NMClampTabDF + "ConfigsTabResetThis", this )
	
	switch( this )
		case 1:
			return ClampBoardWavesReset( io, config )
		case 2:
			return ClampBoardWavesReset( io, -1 )
		case 3:
			return ClampBoardWavesReset( "ADC", -1 ) + ClampBoardWavesReset( "DAC", -1 ) + ClampBoardWavesReset( "TTL", -1 )
	endswitch
	
	return -1

End // ConfigsTabWavesResetAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabPreSampAsk( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable numSamples = 10
	String name, select = "PreSample", modeStr = ""
	
	Variable config = ConfigsTabIOnum()
	
	if ( on == 1 )
		
		Prompt select " ", popup "PreSample;Telegraph Gain;Telegraph Mode;Telegraph Freq;Telegraph Cap;"
		DoPrompt "ADC input", select
		
		if ( V_flag == 0 )
		
			strswitch( select )
		
				case "PreSample":
		
					Prompt numSamples "number of samples to acquire:"
					DoPrompt "Pre-sample ADC input", numSamples
					
					if ( V_flag == 0 )
						modeStr = "PreSamp=" + num2istr( numSamples )
					endif
					
					break
			
				case "Telegraph Gain":
				
					modeStr = ClampTGainPrompt()
					
					if ( strsearch( modeStr, "MultiClamp", 0 ) > 0 )
						if ( exists( "AxonTelegraphFindServers" ) != 4 )
							NMMultiClampTelegraphHowTo()
						endif
					endif
					
					break
					
				case "Telegraph Mode":
					modeStr = ClampTelegraphPrompt( "Mode" )
					break
				
				case "Telegraph Freq":
					modeStr = ClampTelegraphPrompt( "Freq" )
					break
				
				case "Telegraph Cap":
					modeStr = ClampTelegraphPrompt( "Cap" )
					break
					
			endswitch
		
		endif
		
	else
	
		name = WaveStrOrDefault( NMClampDF + "ADCname", config, "" )
	
		if ( StringMatch( name[0, 4], "TGain" ) == 1 )
			name = ClampBoardNextDefaultName( "ADC", config )
			ClampBoardNameSet( "ADC", config, name )
		elseif ( StringMatch( name[0, 4], "Tmode" ) == 1 )
			name = ClampBoardNextDefaultName( "ADC", config )
			ClampBoardNameSet( "ADC", config, name )
		elseif ( StringMatch( name[0, 4], "TFreq" ) == 1 )
			name = ClampBoardNextDefaultName( "ADC", config )
			ClampBoardNameSet( "ADC", config, name )
		elseif ( StringMatch( name[0, 3], "TCap" ) == 1 )
			name = ClampBoardNextDefaultName( "ADC", config )
			ClampBoardNameSet( "ADC", config, name )
		endif
		
	endif
	
	return ClampBoardModeSet( config, modeStr )
	
End // ConfigsTabPreSampAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ConfigsTabTGainPrompt()

	Variable board, chan, output
	String name, chanStr, modeStr = ""

	Variable config = ConfigsTabIOnum()
	String instr = StrVarOrDefault( NMClampTabDF + "TelegraphInstrument", "" )
	String blist = StrVarOrDefault( NMClampDF + "BoardList", "" )

	Prompt instr "telegraphed instrument:", popup NM_ClampTelegraphInstrumentList
	
	DoPrompt "Telegraph Gain", instr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( NMClampTabDF + "TelegraphInstrument", instr )
	
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
	
	name = "TGain_" + instr[0, 2]

	modeStr = ClampTGainStr( board, chan, instr )
	
	ClampBoardNameSet( "ADC", config, name )
	ClampBoardUnitsSet( "ADC", config, "V" )
	ClampBoardScaleSet( "ADC", config, 1 )
	
	SetNMstr( NMClampTabDF + "TelegraphInstrument", instr )
	
	return modeStr
	
End // ConfigsTabTGainPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function ConfigsTabConfigsFromStims()
	String ctrlName
	
	Variable scnt
	String sdf, sname, sList = StimList()
	
	for ( scnt = 0; scnt < ItemsInList( sList ); scnt += 1 )
	
		sname = StringFromList( scnt, sList )
		sdf = NMStimsDF + sname + ":"
		
		if ( WaveExists( $sdf + "ADCname" ) == 0 )
			sList = RemoveFromList( sname, sList ) // old board config waves do not exist
		endif
	
	endfor
	
	if ( ItemsInList( sList ) == 0 )
		DoAlert 0, "There are no stimulus files to extract board configurations from. Try opening older stimulus files and reselecting Extract button."
		return 0
	elseif ( ItemsInList( sList ) > 1 )
		sList = "All;" + sList
	endif
	
	sname = "All"
	
	Prompt sname, "select stimulus:", popup sList
			
	DoPrompt "Extract Board Configs From Stimulus Files", sname 

	if ( V_flag == 0 )
	
		if ( StringMatch( sname, "All" ) == 1 )
			sname = slist
		endif
		
		ClampBoardConfigsFromStims( "ADC", sname )
		ClampBoardConfigsFromStims( "DAC", sname )
		ClampBoardConfigsFromStims( "TTL", sname )
		
	endif
	
End // ConfigsTabConfigsFromStims

//****************************************************************
//****************************************************************
//
//	Notes tab control functions defined below
//
//****************************************************************
//****************************************************************

Function NMNotesTab( enable )
	Variable enable
	
	if ( enable )
	
		NMClampNotesWavesUpdate()
		
	endif
	
End // NMNotesTab

//****************************************************************
//****************************************************************

Structure NMClampNotesLBWaves

	String header, file, acq

EndStructure // NMClampNotesLBWaves

//****************************************************************
//****************************************************************

Function NMClampNotesLBWavesDefault( lb )
	STRUCT NMClampNotesLBWaves &lb
	
	lb.header = NMClampTabDF + "LBNotesHeader"
	lb.file = NMClampTabDF + "LBNotesFile"
	lb.acq = NMClampTabDF + "LBNotesAcq"
	
	if ( !WaveExists( $lb.header ) )
		Make /T/N=( 3, 4 ) $lb.header = ""
	endif
	
	if ( !WaveExists( $lb.file ) )
		Make /T/N=( 3, 4 ) $lb.file = ""
	endif
	
	if ( !WaveExists( $lb.acq ) )
		Make /T/N=( 3, 2 ) $lb.acq = ""
	endif
	
End // NMClampNotesLBWavesDefault

//****************************************************************
//****************************************************************

Function NMClampNotesWavesUpdate()
	
	Variable numItems, rows, icnt, jcnt, numValue
	String varName, varName2, strValue
	
	String hnlist = NMNotesVarList( NMNotesDF, "H_", "numeric" )
	String hslist = NMNotesVarList( NMNotesDF, "H_", "string" )
	String fnlist = NMNotesVarList( NMNotesDF, "F_", "numeric" )
	String fslist = NMNotesVarList( NMNotesDF, "F_", "string" )
	
	String notelist = ListMatch( fslist, "*note*", ";" ) // note strings
	
	notelist = SortList( notelist, ";", 16 )
	
	fslist = RemoveFromList( notelist, fslist, ";") // remove note strings
	
	fnlist = RemoveFromList( NMNotesBasicList( "F", 0 ), fnlist, ";" )
	fslist = RemoveFromList( NMNotesBasicList( "F", 1 ), fslist, ";" )
	
	STRUCT NMClampNotesLBWaves lb
	
	NMClampNotesLBWavesDefault( lb )
	
	numItems = ItemsInList( hslist ) + ItemsInList( hnlist )
	rows = numItems + 3
	
	if ( DimSize( $lb.header, 0 ) < rows )
		Redimension /N=( rows, -1 ) $lb.header
	endif
	
	Wave /T wtemp = $lb.header
	
	wtemp = ""
	wtemp[][ 0 ] = "+"
	
	for ( icnt = 0 ; icnt < ItemsInList( hslist ) ; icnt += 1 )
		varName = StringFromList( icnt, hslist )
		varName2 = ReplaceString( "H_", varName, "" )
		strValue = StrVarOrDefault( NMNotesDF + varName, "" )
		wtemp[ jcnt][ 0 ] = "-"
		wtemp[ jcnt][ 1 ] = varName2
		wtemp[ jcnt][ 2 ] = strValue
		wtemp[ jcnt][ 3 ] = "T"
		jcnt += 1
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( hnlist ) ; icnt += 1 )
	
		varName = StringFromList( icnt, hnlist )
		varName2 = ReplaceString( "H_", varName, "" )
		numValue = NumVarOrDefault( NMNotesDF + varName, Nan )
		
		wtemp[ jcnt][ 0 ] = "-"
		wtemp[ jcnt][ 1 ] = varName2
		
		if ( numtype( numValue ) == 2 )
			wtemp[ jcnt][ 2 ] = ""
		else
			wtemp[ jcnt][ 2 ] = num2str( numValue )
		endif
		
		wtemp[ jcnt][ 3 ] = "N"
		
		jcnt += 1
		
	endfor
	
	numItems = ItemsInList( fslist ) + ItemsInList( fnlist )
	rows = numItems + 3
	
	if ( DimSize( $lb.file, 0 ) < rows )
		Redimension /N=( rows, -1 ) $lb.file
	endif
	
	Wave /T wtemp = $lb.file
	
	wtemp = ""
	wtemp[][ 0 ] = "+"
	
	jcnt = 0
	
	for ( icnt = 0 ; icnt < ItemsInList( fslist ) ; icnt += 1 )
		varName = StringFromList( icnt, fslist )
		varName2 = ReplaceString( "F_", varName, "" )
		strValue = StrVarOrDefault( NMNotesDF + varName, "" )
		wtemp[ jcnt][ 0 ] = "-"
		wtemp[ jcnt][ 1 ] = varName2
		wtemp[ jcnt][ 2 ] = strValue
		wtemp[ jcnt][ 3 ] = "T"
		jcnt += 1
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( fnlist ) ; icnt += 1 )
		varName = StringFromList( icnt, fnlist )
		varName2 = ReplaceString( "F_", varName, "" )
		numValue = NumVarOrDefault( NMNotesDF + varName, Nan )
		
		wtemp[ jcnt][ 0 ] = "-"
		wtemp[ jcnt][ 1 ] = varName2
		
		if ( numtype( numValue ) == 2 )
			wtemp[ jcnt][ 2 ] = ""
		else
			wtemp[ jcnt][ 2 ] = num2str( numValue )
		endif
		
		wtemp[ jcnt][ 3 ] = "N"
		
		jcnt += 1
		
	endfor
	
	Wave /T wtemp = $lb.acq
	
	wtemp = ""
	wtemp[][ 0 ] = "+"
	
End // NMClampNotesWavesUpdate

//****************************************************************
//****************************************************************

Function NMClampNotesLBControl( ctrlName, row, col, event ) : ListboxControl
	String ctrlName // name of this control
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
	
	if ( event != 2 )
		return 0
	endif
	
	STRUCT NMClampNotesLBWaves lb
	
	NMClampNotesLBWavesDefault( lb )
	
	String cname = ReplaceString( "CT4_Notes", ctrlName, "" )
	
	strswitch( cname )
	
		case "Header":
		
			Wave /T wtemp = $lb.header
			
			if ( StringMatch( wtemp[ row ][ 0 ], "+" ) )
			
				print "add"
			
			elseif ( StringMatch( wtemp[ row ][ 0 ], "-" ) )
			
				if ( col == 0 )
					print "remove"
				else
					print "edit"
				endif
			
			endif
			
			break
			
		case "File":
			break
		case "Acq":
			break
	endswitch

End // NMClampNotesLBControl

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Pulse Generator tab control functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseTabPrefixSelect()

	return StrVarOrDefault( NMClampTabDF+"PulsePrefix", "" )

End // PulseTabPrefixSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTabCall( select, varNum, varStr )
	String select
	Variable varNum
	String varStr
	
	Variable icnt, updateWaves = 1, updateTab = 1
	String paramList, sdf = StimDF()
	
	String pPrefix = PulseTabPrefixSelect()
	
	ClampError( 0, "" )
	
	if ( strlen( pPrefix ) == 0 )
		DoAlert 0, "There is currently no selected DAC or TTL output for this stimulus protocol."
		return -1
	endif
	
	strswitch( select )
	
		case "WavePrefix":
		
			updateWaves = 0
		
			if ( strlen( varStr ) > 0 )
	
				icnt = strsearch( varStr," : ",0 )
				
				if ( icnt >= 0 )
					varStr = varStr[0,icnt-1]
				else
					varStr = ""
				endif
				
				SetNMstr( NMClampTabDF + "PulsePrefix", varStr )
				
			endif
			
			break
			 
		case "Table":
			PulseTableManager( 1 )
			DoWindow /F PG_StimTable
			return 0
			
		case "PulseOff":
		case "UseMyWaves":
			SetNMvar( sdf + "PulseGenOff", varNum )
			//StimWavesCheck( sdf, 1 )
			break
	
		case "Display":
			updateWaves = 0
			StimWavesCheck( sdf, 0 )
			PulseGraph( 1 )
			break
			
		case "AllOutputs":
			SetNMvar( NMClampTabDF + "PulseAllOutputs", varNum )
			PulseGraph( 1 )
			return 0
			
		case "AllWaves":
			SetNMvar( NMClampTabDF + "PulseAllWaves", varNum )
			PulseGraph( 1 )
			return 0
			
		case "AutoScale":
			SetNMvar( NMClampTabDF + "PulseAutoScale", varNum )
			PulseGraphAxesSave()
			PulseGraph( 1 )
			return 0
	
	endswitch
	
	if ( updateWaves == 1 )
		StimWavesCheck( sdf, 1 )
	endif
	
	if ( updateTab == 1 )
		StimTabPulse( 1 )
	endif

End // PulseTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTabPopup( ctrlName, popNum, popstr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popstr
	
	ctrlName = ctrlName[ 4, inf ]
	
	PulseTabCall( ctrlName, popNum, popstr )
	
End // PulseTabPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTabButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ctrlName[ 4, inf ]
	
	PulseTabCall( ctrlName, Nan, "" )

End // PulseTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTabCheckbox( ctrlName, checked ) : CheckboxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 4, inf ]
	
	PulseTabCall( ctrlName, checked, "" )
	
End // PulseTabCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseSetVar( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	PulseGraph( 1 )
	//DoWindow /F $NMPanelName
	
End // PulseSetVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseConfigWaveName( [ df, pulsePrefix ] )
	String df // data folder
	String pulsePrefix // e.g. "DAC_0"
	
	String wName
	
	if ( ParamIsDefault( df ) )
		df = StimDF()
	endif
	
	if ( ParamIsDefault( pulsePrefix ) )
		pulsePrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	endif
	
	if ( strlen( pulsePrefix ) > 0 )
	
		wName = pulsePrefix + "_pulse"
		
		wName = ReplaceString( "__", wName, "_" )
		
		return df + wName
		
	endif
	
	return ""
	
End // PulseConfigWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPulseWaveConfigGet( configNum )
	Variable configNum
	
	String pcwName = PulseConfigWaveName()
	
	if ( !WaveExists( $pcwName ) )
		return ""
	endif
	
	if ( ( configNum < 0 ) || ( configNum >= numpnts( $pcwName ) ) )
		return ""
	endif

	Wave /T pulse = $pcwName
	
	return pulse[ configNum ]
	
End // NMPulseWaveConfigGet

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseConfigsCheck()

	Variable pcnt, npulses, warnings
	String paramList, warningStr
	String sdf = StimDF()
	
	String pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	String currentStim = StimCurrent()
	
	String pcwName = PulseConfigWaveName()
	
	if ( strlen( pPrefix ) == 0 )
		return 0
	endif
	
	if ( !WaveExists( $pcwName ) )
		return 0
	endif

	Wave /T pulse = $pcwName
	
	npulses = numpnts( pulse )
	
	for ( pcnt = 0; pcnt < npulses; pcnt += 1 )
		
		warningStr = "NClamp warning : " + currentStim + " : " + NMChild( pcwName ) + " : config #" + num2istr( pcnt )
		
		paramList = pulse[ pcnt ]
		
		if ( strlen( paramList ) == 0 )
			continue
		endif
		
		warnings += PulseConfigCheck( paramList, sdf = sdf, warningStr = warningStr )
		
	endfor
	
	return warnings

End // PulseConfigsCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseConfigCheck( paramList [ sdf, warningStr ] )
	String paramList
	String sdf
	String warningStr
	
	String shape, paramStr
	Variable icnt, jcnt, warnings, waveNum, waveDelta, onset, delta
	
	if ( ParamIsDefault( sdf ) )
		sdf = StimDF()
	endif
	
	if ( ParamIsDefault( warningStr ) )
		warningStr = ""
	endif
	
	Variable numStimWaves = NumVarOrDefault( sdf + "NumStimWaves", 0 )
	Variable waveLength = NumVarOrDefault( sdf + "WaveLength", 0 )
			
	shape = StringByKey( "pulse", paramList, "=" )
	
	if ( WhichListItem( shape, NMPulseList, ";", 0, 0 ) == -1 )
		if ( !WaveExists( $sdf + shape ) )
			NMHistory( warningStr + " : unrecognized pulse shape : " + shape )
			warnings += 1
		endif
	endif
	
	waveNum = NMPulseWaveNum( paramList )
	waveDelta = NMPulseWaveDelta( paramList )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) || ( waveNum >= numStimWaves ) )
		NMHistory( warningStr + " : wave number out of range : " + num2istr( waveNum ) )
		warnings += 1
	endif
	
	onset = NMPulseNumByKey( "onset", paramList, 0 )
	
	if ( ( numtype( onset ) == 0 ) && ( ( onset < 0 ) || ( onset > waveLength ) ) )
		NMHistory( warningStr + " : pulse onset out of range : " + num2str( onset ) )
	endif
	
	if ( waveDelta > 0 )
		return warnings
	endif
	
	// find possible deltas
		
	for ( icnt = 0 ; icnt < ItemsInList( paramList ) ; icnt += 1 )
	
		paramStr = StringFromList( icnt, paramList )
		
		if ( strsearch( paramStr, "wave=", 0 ) == 0 )
			continue
		endif
		
		jcnt = strsearch( paramStr, ",", 0 )
		
		if ( jcnt > 0 )
			
			delta = str2num( paramStr[ jcnt + 1, inf ] )
			
			if ( ( numtype( delta ) == 0 ) && ( delta > 0 ) )
				NMHistory( warningStr + " : found parameter delta value(s) but wave delta = 0" )
				warnings += 1
				break
			endif
			
		endif
		
	endfor
	
	return warnings

End // PulseConfigsCheck

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Pulse Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraph( force )
	Variable force
	
	String sdf = StimDF() // stim data folder
	
	Variable x0 = 100, y0 = 5, xinc = 140
	Variable madeGraph
	
	String ampUnits
	String wName, wList, pPrefix, pPrefixList
	
	String gName = NMPulseGraphName
	String gTitle = StimCurrent()
	String Computer = NMComputerType()
	
	Variable numStimWaves = NumVarOrDefault( sdf + "NumStimWaves", 0 )
	
	Variable tabnum = NumVarOrDefault( NMClampTabDF + "CurrentTab", 0 )
	
	Variable allout = NumVarOrDefault( NMClampTabDF + "PulseAllOutputs", 0 )
	Variable allwaves = NumVarOrDefault( NMClampTabDF + "PulseAllWaves", 1 )
	Variable autoscale = NumVarOrDefault( NMClampTabDF + "PulseAutoScale", 1 )
	Variable wNum = NumVarOrDefault( NMClampTabDF + "PulseWaveNum", 0 )
	
	if ( NMStimChainOn( "" ) == 1 )
		return 0
	endif
	
	PulseGraphAxesSave() // save axes values
	
	//StimWavesCheck( sdf, 0 )
	
	if ( ( force == 1 ) || ( WinType( gName ) == 1 ) )
	
		if ( allwaves == 1 )
			wNum = -1
		endif
		
		if ( wNum >= numStimWaves )
			SetNMvar( NMClampTabDF + "PulseWaveNum", 0 )
			wNum = 0
		endif
		
		pPrefixList = StimPrefixListAll( sdf )
		
		pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
		
		if ( allout == 1 )
			pPrefixList = RemoveFromList( pPrefix, pPrefixList )
			pPrefixList = AddListItem( pPrefix, pPrefixList ) // this puts current prefix first
			wlist = StimWaveList( sdf, pPrefixList, wNum )
		else
			wlist = StimWaveList( sdf, pPrefix, wNum )
		endif
	
		if ( ( ItemsInlist( wlist ) == 0 ) && ( ItemsInlist( pPrefixList ) > 0 ) )
			pPrefix = StringFromList( 0,pPrefixList ) // no waves, try another prefix
			wlist = StimWaveList( sdf, pPrefix, wNum )
			SetNMstr( NMClampTabDF + "PulsePrefix", pPrefix )
		endif
	
		if ( ( ItemsInlist( wlist ) == 0 ) && ( WinType( NMPulseGraphName ) == 0 ) )
			return 0
		endif
		
		wlist = PulseGraphWaveList( sdf, wlist ) // convert wlist do display waves
		
		madeGraph = PulseGraphUpdate( sdf, wlist ) // NM_PulseGen.ipf
		
		if ( madeGraph == 1 )
		
			ModifyGraph /W=$NMPulseGraphName margin( left )=60, margin( right )=0, margin( top )=19, margin( bottom )=0
			
			if ( StringMatch( computer, "mac" ) == 1 )
				y0 = 3
			endif
			
			Checkbox CT2_AllOutputs, value=allout, pos={x0,y0}, title="All Outputs", size={16,18}, proc=PulseTabCheckbox, win=$NMPulseGraphName
	
			Checkbox CT2_AllWaves, value=allwaves, pos={x0+1*xinc,y0}, title="All Waves", size={16,18}, proc=PulseTabCheckbox, win=$NMPulseGraphName
	
			SetVariable CT2_WaveNum, title="Wave", pos={x0+2*xinc,y0-1}, size={80,50}, limits={0,inf,1}, win=$NMPulseGraphName
			SetVariable CT2_WaveNum, value=$NMClampTabDF+"PulseWaveNum", proc=PulseSetVar, win=$NMPulseGraphName
			
			Checkbox CT2_AutoScale, value=autoscale, pos={x0+3*xinc,y0}, title="AutoScale", size={16,18}, proc=PulseTabCheckbox, win=$NMPulseGraphName
			
		else
		
			Checkbox CT2_AllOutputs, win=$NMPulseGraphName, value=allout
			Checkbox CT2_AllWaves, win=$NMPulseGraphName, value=allwaves
			Checkbox CT2_AutoScale, win=$NMPulseGraphName, value=autoscale
			
		endif
		
		if ( allwaves == 1 )
			SetNMvar( NMClampTabDF + "PulseWaveNum", 0 )
			SetVariable CT2_WaveNum, win=$NMPulseGraphName, noedit = 1, limits={0,numStimWaves-1,0}
		else
			SetVariable CT2_WaveNum, win=$NMPulseGraphName, noedit = 0, limits={0,numStimWaves-1,1}
		endif
	
		ampUnits = StimConfigStr( sdf, pPrefix, "name" )
		
		if ( strlen( ampUnits ) == 0 )
			ampUnits = pPrefix
		else
			ampUnits += " ( " + StimConfigStr( sdf, pPrefix, "units" ) + " )"
		endif
		
		if ( ItemsInList( wlist ) > 0 )
		
			Label /Z/W=$gName left, ampUnits
			Label /Z/W=$gName bottom, NMXunits
			
			if ( allout == 0 )
			
				if ( allwaves == 0 )
					gTitle += " : " + pPrefix + " : " + "Wave" + num2istr( wNum )
				else
					gTitle += " : " + pPrefix + " : " + "All Waves"
				endif
				
			else
			
				if ( allwaves == 0 )
					gTitle += " : " + "All Outputs : " + "Wave" + num2istr( wNum )
				else
					gTitle += " : " + "All Outputs : " + "All Waves"
				endif
				
			endif
			
		else

			gTitle += " : " + "No Outputs"
			
		endif
		
		DoWindow /T $gName, gTitle
		
		if ( force == 1 )
			DoWindow /F $NMPulseGraphName
		endif
		
		PulseGraphAxesSet()
		
	endif

End // PulseGraph

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphRemoveWaves()

	Variable wcnt
	String wList, wName, gName = NMPulseGraphName
	
	if ( WinType( gName ) != 1 )
		return 0
	endif
	
	wList = TraceNameList( gName, ";", 1 )
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		wName = StringFromList( wcnt, wList )
		RemoveFromGraph /W=$gName /Z $wName
	endfor

End // PulseGraphRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphAxesSave()

	String gName = NMPulseGraphName
		
	if ( WinType( gName ) == 1 )
	
		GetAxis /Q/W=$gName bottom
	
		SetNMvar( NMClampTabDF + "Xmin", V_min )
		SetNMvar( NMClampTabDF + "Xmax", V_max )
		
		GetAxis /Q/W=$gName left
		
		SetNMvar( NMClampTabDF + "Ymin", V_min )
		SetNMvar( NMClampTabDF + "Ymax", V_max )
		
	endif

End // PulseGraphAxesSave

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseGraphAxesSet()
	
	String gName = NMPulseGraphName
	
	Variable autoscale = NumVarOrDefault( NMClampTabDF + "PulseAutoScale", 1 )
	
	Variable xmin = NumVarOrDefault( NMClampTabDF + "Xmin", 0 )
	Variable xmax = NumVarOrDefault( NMClampTabDF + "Xmax", 1 )
	Variable ymin = NumVarOrDefault( NMClampTabDF + "Ymin", 0 )
	Variable ymax = NumVarOrDefault( NMClampTabDF + "Ymax", 1 )
	
	if ( autoscale == 1 )
		SetAxis /W=$gName/A
		return 0
	endif
	
	SetAxis /W=$gName bottom xmin, xmax
	SetAxis /W=$gName left ymin, ymax
		
End // PulseGraphAxesSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseGraphWaveList( sdf, wlist )
	String sdf
	String wlist
	
	Variable wcnt
	String wName, dlist = ""
	
	Variable off = NumVarOrDefault( sdf + "PulseGenOff", 0 )
	
	for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wlist )
		
		if ( ( off == 1 ) && ( WaveExists( $sdf + "My"+wName ) == 1 ) )
			dlist = AddListItem( "My"+wName, dlist ) // display "My" waves ( MyDAC, MyTTL )
		else
			dlist = AddListItem( "u"+wName, dlist ) // display unscaled waves ( uDAC, uTTL )
		endif
		
	endfor
	
	return dlist
	
End // PulseGraphWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseWaveCheck( io, config )
	String io // "DAC" or "TTL"
	Variable config // config Num ( -1 ) for all
	
	Variable icnt, ibgn = config, iend = config
	String pulsePrefix, pwName, wName
	String sdf = StimDF()
	String bdf = NMStimBoardDF(sdf)
	
	if ((StringMatch(io, "DAC") == 0) && (StringMatch(io, "TTL") == 0))
		return -1
	endif
	
	wName = bdf + io + "name"
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	if ( config == -1 )
		ibgn = 0
		iend = numpnts( $wName ) - 1
	endif
	
	for ( icnt = ibgn; icnt <= iend; icnt += 1 )
	
		pulsePrefix = io + "_" + num2istr( icnt )
		pwName = PulseConfigWaveName( pulsePrefix = pulsePrefix )
		
		if ( NMStimBoardConfigIsActive( sdf, io, config ) == 0 )
			continue
		endif
		
		if ( WaveExists( $pwName ) == 0 )
			Make /N=0/T $pwName
		endif
		
	endfor
	
	return 0
	
End // PulseWaveCheck

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Pulse Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableManager( select )
	Variable select // ( 0 ) update ( 1 ) make ( 2 ) save
	
	String pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	String pcwName = PulseConfigWaveName()
	
	if ( strlen( pPrefix ) == 0 )
		return 0
	endif
	
	switch( select )
		case 0:
		case 1:
			PulseTableUpdate( pcwName, select )
			break
		case 2:
			break
	endswitch
	
End // PulseTableManager

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableUpdate( pcwName, force )
	String pcwName // pulse wave name
	Variable force // ( 0 ) update if exists ( 1 ) force make
	
	String tName = "PG_StimTable"
	String sdf = StimDF()
	
	String pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	String ioName = StimConfigStr( sdf, pcwName, "name" )
	
	if ( strlen( pPrefix ) == 0 )
		return 0
	endif
	
	if ( strlen( pcwName ) == 0 )
		pcwName = PulseConfigWaveName()
	endif
	
	if ( WinType( tName ) == 0 )
	
		if ( force == 0 )
			return 0
		else
			tName = PulseTableMake( pcwName, NMClampTabDF, "" )
		endif
		
	endif
	
	if ( ( strlen( tName ) == 0 ) || ( WinType( tName ) == 0 ) )
		return -1
	endif
		
	DoWindow /T $tName, ioName + " : " + NMChild( pcwName )

End // PulseTableUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseTableMake( pcwName, tdf, prefix )
	String pcwName, tdf, prefix
	
	String tName = StimTable( StimDF(), pcwName, tdf, prefix )
	
	SetWindow $tName hook=PulseTableHook, hookevents=1 
	
	return tName
	
End // PulseTableMake

//****************************************************************
//****************************************************************
//****************************************************************

Function PulseTableHook( infoStr )
	string infoStr
	
	String infoStr2
	
	string event = StringByKey( "EVENT", infoStr )
	string winNameStr = StringByKey( "WINDOW", infoStr )
	
	if ( StringMatch( winNameStr, NMStimPulseTable ) == 0 )
		return 0 // wrong window
	endif
	
	strswitch( event )
		case "activate":
		case "moved":
			break
		case "deactivate":
		case "kill":
			PulseTableManager( 2 )
			StimWavesCheck( StimDF(), 1 )
			PulseGraph( 0 )
	endswitch
	
	return 0

End // PulseTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampListboxUpdate_DEPRECATED()

	Variable icnt, ibgn, numConfigs, numRows, extraRows = 3
	String wName = "PulseConfigs"
	String ename = wName + "Editable"
	
	String pcwName = PulseConfigWaveName()
	
	//Variable editByPrompt = NumVarOrDefault( NMClampDF + "PulseEditByPrompt", 1 )
	
	if ( WaveExists( $pcwName ) )
	
		Wave /T pulses = $pcwName
		
		for ( icnt = 0 ; icnt < numpnts( pulses ) ; icnt += 1 )
			if ( strlen( pulses[ icnt ] ) > 0 )
				numConfigs += 1
			endif
		endfor
		
		numRows = numConfigs + extraRows
		
	else
	
		numRows = extraRows
	
	endif
	
	Make /O/T/N=( numRows, 2 ) $( NMClampDF + wName ) = ""
	Make /O/N=( numRows, 2 ) $( NMClampDF + ename ) = 0
	
	Wave /T params = $NMClampDF + wName
	Wave paramsEditable = $NMClampDF + ename
	
	if ( WaveExists( $pcwName ) )
	
		Wave /T pulses = $pcwName
		
		for ( icnt = 0 ; icnt < numpnts( pulses ) ; icnt += 1 )
		
			if ( strlen( pulses[ icnt ] ) > 0 )
			
				params[ icnt ][ 0 ] = "-"
				params[ icnt ][ 1 ] = pulses[ icnt ]
				
				//if ( editByPrompt )
					paramsEditable[ icnt ][ 1 ] = 0
				//else
					//paramsEditable[ icnt ][ 1 ] = 3
				//endif
				
				ibgn = icnt + 1
				
			endif
			
		endfor
	
	endif
	
	for ( icnt = ibgn ; icnt < numRows ; icnt += 1 )
		params[ icnt ][ 0 ] = "+"
		paramsEditable[ icnt ][ 1 ] = 0
	endfor
	
End // NMClampListboxUpdate_DEPRECATED

//****************************************************************
//****************************************************************
//****************************************************************

Function /S PulseConfigOnOffDelete( [ configNum ] ) // DEPRECATED // use NMPulseLB1PromptOOD()
	Variable configNum // pulse config number ( -1 ) for all
	
	Variable icnt, numPulses, off
	String paramList, pStr, selectStr, trainStr = "", allStr, noteStr, plist = "", titleStr
	String sdf = StimDF()
	
	String pPrefix = StrVarOrDefault( NMClampTabDF + "PulsePrefix", "" )
	String pcwName = PulseConfigWaveName()
	
	if ( ParamIsDefault( configNum ) )
		configNum = NaN
	endif
	
	if ( !WaveExists( $pcwName ) )
		return ""
	endif
	
	numPulses = numpnts( $pcwName )
	
	if ( numPulses == 0 )
		DoAlert 0, "There are no pulse configs to edit."
		return ""
	endif
	
	Wave /T pulses = $pcwName
	
	if ( ( configNum == -1 ) && ( numPulses == 1 ) )
		configNum = 0
	endif
	
	titleStr = "Remove Pulse Config"
	
	if ( ( numtype( configNum ) == 0 ) && ( configNum >= 0 ) && ( configNum < numPulses ) )
	
		paramList = pulses[ configNum ]
	
		pStr = num2istr( configNum )
	
		off = str2num( StringByKey( "off", paramList, "=" ) )
		
		trainStr = StringByKey( "train", paramList, "=" )
		
		allStr = "turn off all pulse configs;turn on all pulse configs;delete all pulse configs;"
		
		if ( off )
			plist = "turn on;delete;"
		else
			plist = "turn off;delete;"
		endif
		
		if ( numPulses > 1 )
			plist += "---;" + allStr
		endif
		
		if ( WaveExists( $sdf + trainStr ) )
			plist += "---;edit " + trainStr + ";"
		endif
		
		titleStr = "Remove Pulse Config #" + pStr
		
	else
	
		plist = allStr
		
	endif
	
	selectStr = ""
	
	Prompt selectStr, " ", popup plist
	DoPrompt titleStr, selectStr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	strswitch( selectStr )
	
		case "turn off all pulse configs":
			NMPulseConfigWaveRemove( pcwName, all = 1, off = 1 )
			break
			
		case "turn on all pulse configs":
			NMPulseConfigWaveRemove( pcwName, all = 1, off = 0 )
			break
			
		case "delete all pulse configs":
		
			DoAlert 2, "Are you sure you want to delete all pulse configurations?"
			
			if ( V_flag == 1 )
				NMPulseConfigWaveRemove( pcwName, all = 1 )
			else
				return ""
			endif
			
			break
	
		default:
		
			if ( strsearch( selectStr, "turn off", 0 ) >= 0 )
			
				NMPulseConfigWaveRemove( pcwName, configNum = configNum, off = 1 )
				
			elseif ( strsearch( selectStr, "turn on", 0 ) >= 0 )
			
				NMPulseConfigWaveRemove( pcwName, configNum = configNum, off = 0 )
				
			elseif ( strsearch( selectStr, "delete", 0 ) >= 0 )
			
				NMPulseConfigWaveRemove( pcwName, configNum = configNum, deleteTrain = 2 )
				
			elseif ( strsearch( selectStr, "edit", 0 ) >= 0 )
			
				if ( ( strlen( trainStr ) > 0 ) && ( WaveExists( $sdf + trainStr ) ) )
					titleStr = sdf + trainStr
					Edit /K=1 $sdf + trainStr as titleStr
					return ""
				endif
				
			endif
	
	endswitch
	
	return "OOD"

End // PulseConfigOnOffDelete

//****************************************************************
//****************************************************************
//****************************************************************