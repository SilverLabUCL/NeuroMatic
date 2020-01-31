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

Constant NMConfigsAutoOpenSave = 0 // auto open/save configs to user's Package directory ( 0 ) no ( 1 ) yes // see NMConfigsHowToSaveToPackages

Static StrConstant ConfigsFileName = "NMConfigs.pxp"

//****************************************************************
//****************************************************************

Function /S ConfigDF( fname ) // return Configurations full-path folder name
	String fname // config folder name ( e.g. "NeuroMatic", "Main", "Stats" )
	
	return NMPackageDF( "Configurations:" + fname )
	
End // ConfigDF

//****************************************************************
//****************************************************************

Function NMConfig( fName, copyConfigs [ update ] )
	String fName // package folder name
	Variable copyConfigs // ( -1 ) copy configs to folder ( 0 ) no copy ( 1 ) copy folder to configs
	Variable update
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	CheckNMConfig( fName ) // create new config folder and variables
	
	if ( copyConfigs != 0 )
		NMConfigCopy( fname, copyConfigs, update = update )
	endif
	
End // NMConfig

//****************************************************************
//****************************************************************

Function CheckNMConfigsAll( [ cleanUp ] )
	Variable cleanUp // remove configs for deprecated variables and strings

	Variable icnt
	String fname, flist = NMConfigList()
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
		fname = StringFromList( icnt, flist )
		CheckNMConfig( fname, cleanUp = cleanUp )
	endfor

End // CheckNMConfigsAll

//****************************************************************
//****************************************************************

Function CheckNMConfig( fname [ cleanUp ] )
	String fname // config folder name ( "NeuroMatic", "Chan", "Stats"... )
	Variable cleanUp // remove configs for deprecated variables and strings
	
	String cdf = ConfigDF( fname )
	Variable noCleanUp = NumVarOrDefault( cdf + "C_NoCleanUp", 0 ) // set this parameter to prevent cleanup action (e.g. Clamp Notes)
	
	CheckNMConfigDF( fname )
	
	if ( cleanUp && !noCleanUp )
		// null lists, which will then be recreated by the following Execute using current version of NM
		SetNMstr( cdf + "C_VarList", "" )
		SetNMstr( cdf + "C_WaveList", "" )
	endif
	
	Execute /Z "NM" + fname + "Configs()" // run particular configs function if it exists
	
	if ( V_Flag == 2003 )
		Execute /Z fname + "Configs()" // try another name
	endif
	
	if ( cleanUp && !noCleanUp )
		// compare new C_VarList to variables that exist in config folder
		// remove variables that are no longer used by NM
		NMConfigCleanUp( fname )
	endif
	
	//UpdateNMConfigMenu()
	
End // CheckNMConfig

//****************************************************************
//****************************************************************

Static Function NMConfigCleanUp( fname ) // remove configs for deprecated variables and strings
	String fname // config folder name
	
	Variable icnt, changeDF
	String vList, vName
	
	String cdf = ConfigDF( fname )
	String pdf = NMPackageDF( fname )
	String saveDF = GetDataFolder( 1 )
	
	if ( DataFolderExists( cdf ) == 0 )
		return -1
	endif
	
	String varList = StrVarOrDefault( cdf + "C_VarList", "" )
	String wList = StrVarOrDefault( cdf + "C_WaveList", "" )
	
	SetDataFolder $cdf
	
	vList = VariableList( "*", ";", 4 )
	vList = RemoveFromList( varList, vList )
	
	for ( icnt = 0 ; icnt < ItemsInList( vList ) ; icnt += 1 )
	
		vName = StringFromList( icnt, vList )
		
		if ( StringMatch( vName[ 0, 1 ], "C_" ) == 1 )
			continue
		endif
		
		KillVariables /Z $cdf + vName
		KillStrings /Z $cdf + "D_" + vName
		KillStrings /Z $cdf + "T_" + vName
		
		if ( DataFolderExists( pdf ) == 1 )
			KillVariables /Z $pdf + vName
			KillStrings /Z $pdf + "D_" + vName
			KillStrings /Z $pdf + "T_" + vName
			//Print "NMConfigCleanUp: killed variable " + pdf + vName
		endif
		
	endfor
	
	vList = StringList( "*", ";" )
	vList = RemoveFromList( varList, vList )
	vList = RemoveFromList( "FileType", vList )
	
	for ( icnt = 0 ; icnt < ItemsInList( vList ) ; icnt += 1 )
	
		vName = StringFromList( icnt, vList )
		
		if ( StringMatch( vName[ 0, 1 ], "C_" ) == 1 )
			continue
		endif
		
		if ( StringMatch( vName[ 0, 1 ], "D_" ) == 1 )
			continue
		endif
		
		if ( StringMatch( vName[ 0, 1 ], "T_" ) == 1 )
			continue
		endif
		
		KillStrings /Z $cdf + vName
		KillStrings /Z $cdf + "D_" + vName
		KillStrings /Z $cdf + "T_" + vName
		
		if ( DataFolderExists( pdf ) == 1 )
			KillStrings /Z $pdf + vName
			KillStrings /Z $pdf + "D_" + vName
			KillStrings /Z $pdf + "T_" + vName
			//Print "NMConfigCleanUp: killed variable " + pdf + vName
		endif
		
	endfor
	
	vList = WaveList( "*", ";", "" )
	vList = RemoveFromList( wList, vList )
	
	for ( icnt = 0 ; icnt < ItemsInList( vList ) ; icnt += 1 )
	
		vName = StringFromList( icnt, vList )
		
		if ( StringMatch( vName[ 0, 1 ], "C_" ) == 1 )
			continue
		endif
		
		KillWaves /Z $cdf + vName
		
		if ( DataFolderExists( pdf ) == 1 )
			KillWaves /Z $pdf + vName
		endif
		
		//Print "Killed wave " + cdf + vName
		
	endfor

	SetDataFolder $saveDf

	return 0
	
End // NMConfigCleanUp

//****************************************************************
//****************************************************************

Function CheckNMConfigDF( fname )
	String fname // config folder name
	
	String df = ConfigDF( "" ) // main config folder
	String sub = df + fname + ":" // subfolder to check
	
	Variable makeDF
	
	CheckNMPackageDF( "Configurations" )
	makeDF = CheckNMPackageDF( "Configurations:"+fname )
	
	SetNMstr( df+"FileType", "NMConfig" )
	SetNMstr( sub+"FileType", "NMConfig" )
	
	return makeDF // ( 0 ) already made ( 1 ) yes, made
	
End // CheckNMConfigDF

//****************************************************************
//****************************************************************

Function /S NMConfigList()

	String flist = FolderObjectList( ConfigDF( "" ), 4 )
	
	if ( FindListItem( "NeuroMatic", flist ) >= 0 )
		flist = RemoveFromList( "NeuroMatic", flist )
		flist = "NeuroMatic;" + flist
	endif
	
	return flist
	
End // NMConfigList

//****************************************************************
//****************************************************************

Function NMConfigCopy( flist, direction [ update ] ) // set configurations
	String flist // config folder name list or "All"
	Variable direction // ( -1 ) config to package folder ( 1 ) package folder to config
	Variable update
	
	Variable icnt, fcnt
	String fname, objName, cdf, df, objList
	
	if ( StringMatch( flist, "All" ) == 1 )
		flist = NMConfigList()
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	for ( fcnt = 0; fcnt < ItemsInList( flist ); fcnt += 1 )
	
		fname = StringFromList( fcnt, flist )
		
		cdf = ConfigDF( fname ) // config data folder
		df = NMPackageDF( fname ) // package data folder
		
		if ( DataFolderExists( cdf ) == 0 )
			continue
		endif
		
		if ( direction == -1 )
			CheckNMPackageDF( fname )
		endif
		
		objList = NMConfigVarList( fname, 2 ) // numbers
		
		for ( icnt = 0; icnt < ItemsInList( objList ); icnt += 1 )
		
			objName = StringFromList( icnt, objList )
			
			if ( ( direction == 1 ) && ( exists( df+objName ) == 2 ) )
				SetNMvar( cdf+objName, NumVarOrDefault( df+objName, Nan ) )
			elseif ( direction == -1 )
				SetNMvar( df+objName, NumVarOrDefault( cdf+objName, Nan ) )
			endif
			
		endfor
		
		objList = NMConfigVarList( fname, 3 ) // strings
		
		for ( icnt = 0; icnt < ItemsInList( objList ); icnt += 1 )
		
			objName = StringFromList( icnt, objList )
			
			if ( ( direction == 1 ) && ( exists( df+objName ) == 2 ) )
				SetNMstr( cdf+objName, StrVarOrDefault( df+objName, "" ) )
			elseif ( direction == -1 )
				SetNMstr( df+objName, StrVarOrDefault( cdf+objName, "" ) )
			endif
			
		endfor
		
		objList = NMConfigVarList( fname, 5 ) // numeric waves
		
		for ( icnt = 0; icnt < ItemsInList( objList ); icnt += 1 )
		
			objName = StringFromList( icnt, objList )
			
			if ( ( direction == 1 ) && ( WaveExists( $( df+objName ) ) == 1 ) )
				Duplicate /O $( df+objName ), $( cdf+objName )
			elseif ( direction == -1 )
				Duplicate /O $( cdf+objName ), $( df+objName )
			endif
			
		endfor
		
		objList = NMConfigVarList( fname, 6 ) // text waves
		
		for ( icnt = 0; icnt < ItemsInList( objList ); icnt += 1 )
		
			objName = StringFromList( icnt, objList )
			
			if ( ( direction == 1 ) && ( WaveExists( $( df+objName ) ) == 1 ) )
				Duplicate /O $( df+objName ), $( cdf+objName )
			elseif ( direction == -1 )
				Duplicate /O $( cdf+objName ), $( df+objName )
			endif
			
		endfor
	
	endfor
	
	if ( update && ( direction == -1 ) )
		UpdateNM( 0 )
	endif
	
	return 0

End // NMConfigCopy

//****************************************************************
//****************************************************************

Function /S NMConfigSaveCall( fname )
	String fname // config folder name

	String flist = NMConfigList()
	
	if ( ( strlen( fname ) == 0 ) || ( FindListItem( fname, flist ) < 0 ) )
	
		fname = "All"
	
		if ( ItemsInList( flist ) == 0 )
			NMDoAlert( "No Configurations to save." )
			return ""
		endif
		
		if ( ItemsInList( flist ) > 1 )
			flist += "All;"
		endif
	
		Prompt fname, "select configuration to save:", popup flist
		DoPrompt "Save Configuration", fname
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	endif
	
	return NMConfigSave( fname, history = 1 )

End // NMConfigSaveCall

//****************************************************************
//****************************************************************

Function /S NMConfigSave( fname [ history ] ) // save config folder
	String fname // config folder fname, or "All"
	Variable history
	
	String folder, tdf, df, file = "NMConfig" + fname
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( fname, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( StringMatch( fname, "All" ) == 1 )
		return NMConfigSaveAll()
	endif

	df = ConfigDF( "" )

	if ( StringMatch( StrVarOrDefault( df+"FileType", "" ), "NMConfig" ) == 0 )
		NMDoAlert( "NMConfigSave Error: folder is not a NM configuration file." )
		return ""
	endif
	
	NMConfigCopy( fname, 1 ) // get current configuration values
	
	tdf = "root:" + file + ":" // temp folder
	
	if ( DataFolderExists( tdf ) == 1 )
		KillDataFolder $tdf // kill temp folder if already exists
	endif
	
	NewDataFolder $RemoveEnding( tdf, ":" )
	
	SetNMstr( tdf+"FileType", "NMConfig" )
	
	DuplicateDataFolder $( df+fname ), $( tdf+fname )
	
	CheckNMPath()
	
	folder = NMFolderSaveToDisk( folder = tdf, extFile = file, path = "NMPath" )
	
	KillNMPath()
	
	if ( DataFolderExists( tdf ) == 1 )
		KillDataFolder $tdf // kill temp folder
	endif
	
	return folder
	
End // NMConfigSave

//****************************************************************
//****************************************************************

Function /S NMConfigSaveAll()
	
	String df = ConfigDF( "" )
	String file = StrVarOrDefault( df+"CurrentFile", "" )
	
	if ( strlen( file ) == 0 )
		file = "NMConfigs"
	endif

	if ( StringMatch( StrVarOrDefault( df+"FileType", "" ), "NMConfig" ) == 0 )
		NMDoAlert( "NMConfigSave Error: folder is not a NM configuration file." )
		return ""
	endif
	
	NMConfigCopy( "All", 1 ) // get current configuration values
	
	CheckNMPath()
	
	file = NMFolderSaveToDisk( folder = df, extFile = file, path = "NMPath" )
	
	KillNMPath()
	
	return file

End // NMConfigSaveAll

//****************************************************************
//****************************************************************

Function NMConfigsHowToSaveToPackages()

	Variable configLine = 23
	
	String txt = "NM configs can be automatically saved within each user's Package folder. "
	txt += "To use, set NMConfigsAutoOpenSave = 1 in the procedure NM_Configurations.ipf "
	txt += "and save the procedure ( Igor Menu/File/Save Procedure ). "
	txt += "To edit, click the pencil icon."

	Execute /Z "SetIgorOption IndependentModuleDev = 1"
	DisplayProcedure /L=( configLine )/W=$"NM_Configurations.ipf"
	
	NMDoAlert( txt, title="NM Configs Auto Save/Open" )

End // NMConfigsHowToSaveToPackages

//****************************************************************
//****************************************************************

Function /S NMConfigsSaveToPackages()
	
	String df = ConfigDF( "" )
	String file = ConfigsFileName
	
	String thisfxn = GetRTStackInfo( 1 )
	
	if ( !DataFolderExists( df ) )
		return ""
	endif
	
	String fullPath = SpecialDirPath("Packages", 0, 0, 0)
	
	fullPath += NMPackage

	if ( StringMatch( StrVarOrDefault( df+"FileType", "" ), "NMConfig" ) == 0 )
		NMDoAlert( thisfxn + " Error: folder is not a NM configuration file." )
		return ""
	endif
	
	NMConfigCopy( "All", 1 ) // get current configuration values
	
	NewPath /O/C/Q NMPath, fullPath
	
	if (V_Flag != 0 )
		NMDoAlert( thisfxn + " Error: failed to created folder: " + fullPath ) 
	endif

	fullPath += ":" + ConfigsFileName

	DFREF saveDF = GetDataFolderDFR()
	
	SetDataFolder $df
	SaveData /O/Q/R fullPath
	
	if (V_Flag != 0 )
		NMDoAlert( thisfxn + " Error: failed to save " + ConfigsFileName )
		fullPath = ""
	else
		NMHistory( "Saved NM configs to User Packages directory " + fullPath )
	endif
	
	SetDataFolder saveDF
	KillPath /Z NMPath
	
	return fullPath

End // NMConfigsSaveToPackages

//****************************************************************
//****************************************************************

Function NMConfigsOpenFromPackages()

	String fullPath = SpecialDirPath("Packages", 0, 0, 0) + NMPackage + ":" + ConfigsFileName
	
	Variable error = NMConfigOpen( fullPath, history = 0, quiet = 1 )
	
	if ( error == 0 )
		NMHistory( "Opened NM configs from User Packages directory " + fullPath )
	endif

End // NMConfigsOpenFromPackages

//****************************************************************
//****************************************************************

Function NMConfigOpen( file [ history, quiet ] )
	String file
	Variable history
	Variable quiet
	
	Variable icnt, dialogue = 0, error = -1
	String flist, fname, folder, odf, ndf, cdf, vlist = "", df = ConfigDF( "" )
	
	Variable nmPrefix = 0 // leave folder name as is
	
	if ( history )
		vlist = NMCmdStr( file, vlist )
		NMCommandHistory( vlist )
	endif
	
	CheckNMPath()
	
	if ( strlen( file ) == 0 )
		dialogue = 1
	endif
	
	folder = NMFileBinOpen( dialogue, ".pxp", "root:", "NMPath", file, 0, nmPrefix = nmPrefix, history = history, quiet = quiet ) // NM_FileManager.ipf
	
	KillNMPath()

	if ( strlen( folder ) == 0 )
		return error // cancel
	endif
	
	if ( IsNMFolder( folder, "NMConfig" ) == 1 )
	
		flist = FolderObjectList( folder, 4 ) // subfolder list
		
		for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
		
			fname = StringFromList( icnt, flist )
			
			if ( StringMatch( fname, "Notes" ) )
				
				odf = folder + ":Notes"
				ndf = folder + ":ClampNotes"
				
				if ( !DataFolderExists( folder + ":ClampNotes" ) )
					fname = "ClampNotes"
					RenameDataFolder $odf, $fname
				endif
				
			endif
			
			odf = folder + ":" + fname
			cdf = df + fname
		
			if ( DataFolderExists( cdf ) == 1 )
				KillDataFolder $cdf // kill config folder
			endif
			
			DuplicateDataFolder $odf, $cdf
			
			NMConfigCopy( fname, -1 ) // set config values
		
		endfor
		
		
		error = 0
		
		CheckNMConfigsAll( cleanUp = 1 )
		CheckNMPaths()
		
	else
	
		NMDoAlert( "Open File Error: file is not a NeuroMatic configuration file." )
		
	endif
	
	if ( DataFolderExists( folder ) == 1 )
		KillDataFolder $folder
	endif
	
	//UpdateNMConfigMenu()
	
	return error

End // NMConfigOpen

//****************************************************************
//****************************************************************

Function NMConfigOpenAuto()

	Variable icnt, error = -1
	String path, flist, fileName, ext = ".pxp"

	CheckNMPath()
	
	PathInfo NMPath
	
	if ( V_flag == 0 )
		return 0
	endif
	
	path = S_path
	
	flist = IndexedFile( NMPath, -1, "????" )
	
	flist = RemoveFromList( "NMConfigs.pxp", flist )
	flist = "NMConfigs.pxp;" + flist // open NMConfigs first
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
	
		fileName = StringFromList( icnt, flist )
		
		if ( StrSearch( fileName, ".ipf", 0, 2 ) >= 0 )
			continue // skip procedure files
		endif
		
		if ( StrSearch( fileName, ext, 0, 2 ) >= 0 )
			error = NMConfigOpen( path + fileName )
		endif
		
	endfor
	
	//UpdateNMConfigMenu()
	
	CheckNMConfigsAll( cleanUp = 1 )
	
	KillNMPath()
	
	PathInfo /S Igor // reset path to Igor

End // NMConfigOpenAuto

//****************************************************************
//****************************************************************

Function NMConfigKillCall( fname )
	String fname // config folder name
	
	String flist = NMConfigList()
	
	if ( ( strlen( fname ) == 0 ) || ( FindListItem( fname, flist ) < 0 ) )
	
		if ( ItemsInList( flist ) == 0 )
			NMDoAlert( "No configuration to kill." )
			return 0
		endif
		
		if ( ItemsInList( flist ) > 1 )
			flist += "All;"
		endif
	
		Prompt fname, "select configuration to kill:", popup flist
		DoPrompt "Kill Configuration", fname
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
	
	endif
	
	return NMConfigKill( fname, history = 1 )

End // NMConfigKillCall

//****************************************************************
//****************************************************************

Function NMConfigKill( flist [ history ] ) // kill config folder
	String flist // config folder list, or "All"
	Variable history
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( flist, "" )
		NMCommandHistory( vlist )
	endif
	
	if ( StringMatch( flist, "All" ) == 1 )
		flist = NMConfigList()
	endif
	
	Variable icnt
	String fname, cdf, df = ConfigDF( "" )
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
		
		fname = StringFromList( icnt, flist )
		
		cdf = df + fname
	
		if ( DataFolderExists( cdf ) == 1 )
			KillDataFolder $cdf // kill config folder
		endif
	
	endfor
	
	UpdateNM( 1 )
	
End // NMConfigKill

//****************************************************************
//****************************************************************

Function NMConfigKill2( fname )
	String fname // config folder name
	
	Variable icnt
	String iName, iList
	
	String cdf = ConfigDF( fname )
	String pdf = NMPackageDF( fname ) // package data folder
	
	iList = NMConfigVarList( fname, 1 ) // waves
	
	for ( icnt = 0 ; icnt < ItemsInList( iList ) ; icnt += 1 )
	
		iName = StringFromList( icnt, iList )
		
		if ( WaveExists( $cdf + iName ) == 1 )
			KillWaves /Z $cdf + iName
		endif
		
		if ( WaveExists( $pdf + iName ) == 1 )
			KillWaves /Z $pdf + iName
		endif
		
	endfor
	
	iList = NMConfigVarList( fname, 2 ) // variables
	
	for ( icnt = 0 ; icnt < ItemsInList( iList ) ; icnt += 1 )
	
		iName = StringFromList( icnt, iList )
		
		if ( exists( cdf + iName ) == 2 )
			KillVariables /Z $cdf + iName
		endif
		
		if ( exists( pdf + iName ) == 2 )
			KillVariables /Z $pdf + iName
		endif
		
	endfor
	
	iList = NMConfigVarList( fname, 3 ) // strings
	
	for ( icnt = 0 ; icnt < ItemsInList( iList ) ; icnt += 1 )
	
		iName = StringFromList( icnt, iList )
		
		if (exists( cdf + iName ) == 2 )
			KillStrings /Z $cdf + iName
		endif
		
		if ( exists( pdf + iName ) == 2 )
			KillStrings /Z $pdf + iName
		endif
		
	endfor
	
End // NMConfigKill2

//****************************************************************
//****************************************************************

Function NMConfigResetCall( fname )
	String fname // config folder name
	
	String flist = NMConfigList()
	
	if ( ItemsInList( flist ) == 0 )
		NMDoAlert( "No configuration to reset." )
		return 0
	endif
	
	if ( ItemsInList( flist ) > 1 )
		flist += "All;"
	endif

	Prompt fname, "select configuration:", popup flist
	DoPrompt "Reset Configs to Default Values", fname
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	return NMConfigReset( fname, history = 1 )

End // NMConfigResetCall

//****************************************************************
//****************************************************************

Function NMConfigReset( flist [ history ] ) // reset config folder
	String flist // config folder list, or "All"
	Variable history
	
	Variable icnt
	String fname
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( flist, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( StringMatch( flist, "All" ) == 1 )
		flist = NMConfigList()
	endif
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
		
		fname = StringFromList( icnt, flist )
		
		if ( StringMatch( fname, "NeuroMatic" ) )
			KillStrings $( NMDF + "TabControlList" )
		endif
	
		NMConfigKill2( fname )
		
		CheckNMConfig( fname, cleanUp = 1 )
	
	endfor
	
	UpdateNM( 1 )
	
End // NMConfigReset

//****************************************************************
//****************************************************************

Function NMConfigVarListAdd( fname, varName )
	String fname // config folder name
	String varName
	
	String df = ConfigDF( fname )
	
	String vList = StrVarOrDefault( df + "C_VarList", "" )
	
	vList = AddListItem( varName, vList, ";", inf )
	
	SetNMstr( df + "C_VarList", vList )
	
End // NMConfigVarListAdd

//****************************************************************
//****************************************************************

Function NMConfigWaveListAdd( fname, wName )
	String fname // config folder name
	String wName // wave name
	
	String df = ConfigDF( fname )
	
	String vList = StrVarOrDefault( df + "C_WaveList", "" )
	
	vList = AddListItem( wName, vList, ";", inf )
	
	SetNMstr( df + "C_WaveList", vList )
	
End // NMConfigWaveListAdd

//****************************************************************
//****************************************************************

Function NMConfigVar( fname, vName, value, infoStr, type )
	String fname, vName
	Variable value
	String infoStr
	String type
	
	String df = ConfigDF( fname )
	String pf = NMPackageDF( fname )
	
	NMConfigVarListAdd( fname, vName )
	
	CheckNMConfigDF( fname ) // check config folder exists
	CheckNMvar( df+vname, NumVarOrDefault( pf+vName, value ) )
	CheckNMstr( df+"D_"+vName, infoStr )
	CheckNMstr( df+"T_"+vName, type )
	
End // NMConfigVar

//****************************************************************
//****************************************************************

Function NMConfigVarRename( fname, oldName, newName )
	String fname
	String oldName, newName

	Variable value

	String cdf = ConfigDF( fname )
	String pdf = NMPackageDF( fname )
	
	if ( exists( cdf + oldName ) == 2 )
	
		value = NumVarOrDefault( cdf + oldName, NaN )
		
		SetNMvar( cdf + newName, value )
		
		KillVariables /Z $cdf + oldName
	
	endif
	
	if ( exists( pdf + oldName ) == 2 )
	
		value = NumVarOrDefault( pdf + oldName, NaN )
		
		SetNMvar( pdf + newName, value )
		
		KillVariables /Z $pdf + oldName
	
	endif
	
End // NMConfigVarRename

//****************************************************************
//****************************************************************

Function NMConfigStr( fname, vName, strValue, infoStr, type )
	String fname, vName, strValue, infoStr, type
	
	String df = ConfigDF( fname )
	String pf = NMPackageDF( fname )
	
	NMConfigVarListAdd( fname, vName )
	
	CheckNMConfigDF( fname ) // check config folder exists
	CheckNMstr( df+vName, StrVarOrDefault( pf+vName, strValue ) )
	CheckNMstr( df+"D_"+vName, infoStr )
	CheckNMstr( df+"T_"+vName, type )
	
End // NMConfigStr

//****************************************************************
//****************************************************************

Function NMConfigStrRename( fname, oldName, newName )
	String fname
	String oldName, newName

	String strValue

	String cdf = ConfigDF( fname )
	String pdf = NMPackageDF( fname )
	
	if ( exists( cdf + oldName ) == 2 )
	
		strValue = StrVarOrDefault( cdf + oldName, "ThisStringDoesNotExist" )
		
		if ( StringMatch( strValue, "ThisStringDoesNotExist" ) == 0 )
		
			SetNMstr( cdf + newName, strValue )
			
			KillStrings /Z $cdf + oldName
		
		endif
	
	endif
	
	if ( exists( pdf + oldName ) == 2 )
	
		strValue = StrVarOrDefault( cdf + oldName, "ThisStringDoesNotExist" )
		
		if ( StringMatch( strValue, "ThisStringDoesNotExist" ) == 0 )
		
			SetNMstr( pdf + newName, strValue )
			
			KillStrings /Z $pdf + oldName
		
		endif
	
	endif
	
End // NMConfigStrRename

//****************************************************************
//****************************************************************

Function NMConfigWave( fname, wName, npnts, value, infoStr )
	String fname, wName
	Variable npnts
	Variable value
	String infoStr
	
	String cw = ConfigDF( fname ) + wName
	String pw = NMPackageDF( fname ) + wName
	
	NMConfigWaveListAdd( fname, wName )
	
	CheckNMConfigDF( fname ) // check config folder exists
	
	infoStr = NMNoteCheck( infoStr )
	
	if ( ( WaveExists( $pw ) == 1 ) && ( WaveExists( $cw ) == 0 ) )
		Duplicate /O $pw $cw
	else
		CheckNMwave( cw, npnts, value )
	endif
	
	NMNoteType( cw, "NM" + fname, "", "", "Description:" + infoStr )
	
End // NMConfigWave

//****************************************************************
//****************************************************************

Function NMConfigWaveRename( fname, oldName, newName )
	String fname
	String oldName, newName

	String cdf = ConfigDF( fname )
	String pdf = NMPackageDF( fname )

	if ( WaveExists( $cdf + oldName ) == 1 )
		Duplicate /O $cdf + oldName $cdf + newName
		KillWaves /Z $cdf + oldName
	endif
	
	if ( WaveExists( $pdf + oldName ) == 1 )
		Duplicate /O $pdf + oldName $pdf + newName
		KillWaves /Z $pdf + oldName
	endif

End // NMConfigWaveRename

//****************************************************************
//****************************************************************

Function NMConfigTWave( fname, wName, npnts, strValue, infoStr )
	String fname, wName
	Variable npnts
	String strValue
	String infoStr
	
	String cw = ConfigDF( fname ) + wName
	String pw = NMPackageDF( fname ) + wName
	
	NMConfigWaveListAdd( fname, wName )
	
	CheckNMConfigDF( fname ) // check config folder exists
	
	infoStr = NMNoteCheck( infoStr )
	
	if ( ( WaveExists( $pw ) == 1 ) && ( WaveExists( $cw ) == 0 ) )
		Duplicate /O $pw $cw
	else
		CheckNMtwave( cw, npnts, strValue )
	endif
	
	NMNoteType( cw, "NM" + fname, "", "", "Description:" + infoStr )
	
End // NMConfigTWave

//****************************************************************
//****************************************************************

Function /S NMConfigVarList( fname, objType )
	String fname // config folder name
	Variable objType // ( 1 ) waves ( 2 ) variables ( 3 ) strings ( 4 ) data folders ( 5 ) numeric wave ( 6 ) text wave
	
	Variable ocnt
	String objName, rlist = ""
	
	String objList = FolderObjectList( ConfigDF( fname ), objType )
	
	if ( objType == 3 ) // strings
	
		for ( ocnt = 0; ocnt < ItemsInList( objList ); ocnt += 1 )
		
			objName = StringFromList( ocnt, objList )
			
			if ( StringMatch( objName[ 0,1 ], "C_" ) == 1 )
				continue
			endif
			
			if ( StringMatch( objName[ 0,1 ], "D_" ) == 1 )
				continue
			endif
			
			if ( StringMatch( objName[ 0,1 ], "T_" ) == 1 )
				continue
			endif
			
			rlist += objName + ";"
			
		endfor
		
		objList = rlist
		
	endif
	
	objList = RemoveFromList( "FileType", objList )
	objList = RemoveFromList( "VarName", objList )
	objList = RemoveFromList( "StrValue", objList )
	objList = RemoveFromList( "NumValue", objList )
	objList = RemoveFromList( "Description", objList )
	
	return objList

End // NMConfigVarList

//****************************************************************
//****************************************************************

Function NMConfigVarSet( tabName, varName, value [ history ] )
	String tabName
	String varName
	Variable value
	Variable history
	
	String vlist = ""
	
	if ( StringMatch( tabName, "NM" ) )
		tabName = "NeuroMatic"
	endif
	
	if ( history )
		vlist = NMCmdStr( tabName, vlist )
		vlist = NMCmdStr( varName, vlist )
		vlist = NMCmdNum( value, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( tabName ) == 0 )
		tabName = CurrentNMTabName()
	endif
	
	String cdf = ConfigDF( tabName )
	String pdf = NMPackageDF( tabName )
	
	if ( exists( cdf + varName ) != 2 )
		return -1
	endif
	
	SetNMvar( cdf + varName, value )
	SetNMvar( pdf + varName, value )
	
	return 0
	
End // NMConfigVarSet

//****************************************************************
//****************************************************************

Function NMConfigStrSet( tabName, strVarName, strValue [ history ] )
	String tabName
	String strVarName
	String strValue
	Variable history
	
	String vlist = ""
	
	if ( StringMatch( tabName, "NM" ) )
		tabName = "NeuroMatic"
	endif
	
	if ( history )
		vlist = NMCmdStr( tabName, vlist )
		vlist = NMCmdStr( strVarName, vlist )
		vlist = NMCmdStr( strValue, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( tabName ) == 0 )
		tabName = CurrentNMTabName()
	endif
	
	String cdf = ConfigDF( tabName )
	String pdf = NMPackageDF( tabName )
	
	if ( exists( cdf + strVarName ) != 2 )
		return -1
	endif
	
	SetNMstr( cdf + strVarName,strValue )
	SetNMstr( pdf + strVarName, strValue )
	
	return 0
	
End // NMConfigStrSet

//****************************************************************
//****************************************************************

Function /S NMConfigTypeNS( tabName, varName )
	String tabName
	String varName
	
	String cdf = ConfigDF( tabName )
	
	if ( exists( cdf + varName ) != 2 )
		return ""
	endif
	
	NVAR /Z varH = $cdf + varName
	
	if ( NVAR_Exists( varH ) )
		return "N" // numeric
	endif
	
	SVAR /Z strH = $cdf + varName
		
	if ( SVAR_Exists( strH ) )
		return "S" // string
	endif
	
	return ""
	
End // NMConfigTypeNS

//****************************************************************
//****************************************************************

Function /S NMConfigEditPrompt( tabName, varName [ title, editType, editDefinition ] )
	String tabName
	String varName
	String title
	Variable editType, editDefinition
	
	Variable numValue
	String strValue, type, definition
	
	String cdf = ConfigDF( tabName )
	String pdf = NMPackageDF( tabName )
	
	if ( ParamIsDefault( title ) )
		title = "Edit NM Config : " + varName
	endif
	
	if ( strlen( varName ) == 0 )
		return ""
	endif
	
	if ( exists( cdf + varName ) != 2 )
		return ""
	endif
	
	String varName2 = "T_" + varName // type
	String varName3 = "D_" + varName // definition
	String typeNS = NMConfigTypeNS( tabName, varName )
	
	Prompt numValue "value:"
	Prompt strValue "value:"
	Prompt type "type:"
	Prompt definition "definition:"
	
	type = StrVarOrDefault( cdf + varName2, "" )
	definition = StrVarOrDefault( cdf + varName3, "" )
	
	if ( StringMatch( typeNS, "N" ) )
	
		numValue = NumVarOrDefault( cdf + varName, NaN )
		
		if ( editType && editDefinition )
			DoPrompt title, numValue, type, definition
		elseif ( editType )
			DoPrompt title, numValue, type
		elseif ( editDefinition )
			DoPrompt title, numValue, definition
		else
			DoPrompt title, numValue
		endif
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMvar( cdf + varName, numValue )
		SetNMvar( pdf + varName, numValue )
		
		strValue = num2str( numValue )
		
	elseif ( StringMatch( typeNS, "S" ) )
	
		strValue = StrVarOrDefault( cdf + varName, "" )
		
		if ( editType && editDefinition )
			DoPrompt title, strValue, type, definition
		elseif ( editType )
			DoPrompt title, strValue, type
		elseif ( editDefinition )
			DoPrompt title, strValue, definition
		else
			DoPrompt title, strValue
		endif
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMstr( cdf + varName, strValue )
		SetNMstr( pdf + varName, strValue )
		
	else
	
		return ""
		
	endif
	
	if ( editType )
		SetNMstr( cdf + varName2, type )
	endif
	
	if ( editDefinition )
		SetNMstr( cdf + varName3, definition )
	endif
	
	return strValue + ";" + type + ";" + definition + ";"
	
End // NMConfigEditPrompt

//****************************************************************
//****************************************************************
//
//	Configuration Edit/Table Functions
//
//****************************************************************
//****************************************************************

Function NMConfigEditCall( fname )
	String fname // config folder name
	
	Variable ok
	
	String flist = NMConfigList()
	
	if ( ( strlen( fname ) == 0 ) || ( FindListItem( fname, flist ) < 0 ) )
	
		if ( ItemsInList( flist ) == 0 )
			NMDoAlert( "No Configurations to edit." )
			return 0
		endif
		
		//if ( ItemsInList( flist ) > 1 )
		//	flist += "All;" // this seems to crash Igor
		//endif
	
		Prompt fname, "select configuration to edit:", popup flist
		DoPrompt "Edit Configurations", fname
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
	
	endif
	
	ok = NMConfigsTabEdit( fname, history = 1 ) // edit via panel
	
	if ( ok < 0 )
		return NMConfigEdit( fname, history = 1 ) // old table
	endif
	
	return ok

End // NMConfigEditCall

//****************************************************************
//****************************************************************

Function NMConfigEdit( flist [ history ] ) // create table to edit config vars
	String flist // config folder name list, or "All"
	Variable history
	
	Variable fcnt, ocnt, icnt, items, numItems, strItems
	
	String fname, objName, tableName, tableTitle, varList, strList, vlist = ""
	String df
	
	STRUCT Rect w
	
	String blankStr = ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
	
	if ( history )
		vlist = NMCmdStr( fname, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( StringMatch( flist, "All" ) == 1 )
		//flist = NMConfigList()
		return -1 // not allowed. crashes Igor.
	endif
	
	for ( fcnt = 0; fcnt < ItemsInList( flist ); fcnt += 1 )
	
		fname = StringFromList( fcnt, flist )
		df = ConfigDF( fname )
		
		Execute /Z "NM" + fname + "ConfigEdit()" // run particular edit tab config if exists
		
		if ( V_Flag == 2003 )
			Execute /Z fname + "ConfigEdit()" // run particular edit tab config if exists
		endif
		
	endfor
	
	for ( fcnt = 0; fcnt < ItemsInList( flist ); fcnt += 1 )
	
		fname = StringFromList( fcnt, flist )
		df = ConfigDF( fname )
	
		tableName = "Config_" + fname
		tableTitle = fname + " Configurations"
	
		varList = NMConfigVarList( fname, 2 )
		strList = NMConfigVarList( fname, 3 )
	
		if ( ( ItemsInList( varList ) == 0 ) && ( ItemsInList( strList ) == 0 ) )
		
			//DoAlert 0, "Located no " + NMQuotes( fname ) + " configurations."
			
			Execute /Z "NM" + fname + "ConfigEdit()" // run particular edit tab config if exists
			
			if ( V_Flag == 2003 )
				Execute /Z fname + "ConfigEdit()" // run particular edit tab config if exists
			endif
			
			continue
			
		endif
		
		numItems = ItemsInList( varList )
		strItems = ItemsInList( strList )
		items = numItems + strItems
		
		if ( ( numItems > 0 ) && ( strItems > 0 ) )
			items += 1 // for seperator
		endif
		
		Make /O/T/N=( items ) $( df+"Description" ) = ""
		Make /O/T/N=( items ) $( df+"VarName" ) = ""
		Make /O/T/N=( items ) $( df+"StrValue" ) = ""
		
		Make /O/N=( items ) $( df+"NumValue" ) = Nan
		
		Wave /T Description = $( df+"Description" )
		Wave /T VarName = $( df+"VarName" )
		Wave /T StrValue = $( df+"StrValue" )
		
		Wave NumValue = $( df+"NumValue" )
		
		if ( WinType( tableName ) == 0 )
		
			NMWinCascadeRect( w )
			
			Edit /K=1/W=(w.left,w.top,w.right,w.bottom)/N=$tableName VarName as tableTitle
			
			if ( numItems > 0 )
				AppendToTable /W=$tableName NumValue
				Execute /Z "ModifyTable width( " + df + "NumValue )=60"
			endif
			
			if ( strItems > 0 )
				AppendToTable /W=$tableName StrValue
				Execute /Z "ModifyTable alignment( " + df + "StrValue )=0, width( " + df + "StrValue )=150"
			endif
			
			AppendToTable Description
			
			Execute /Z "ModifyTable title( Point )= " + NMQuotes( "Entry" )
			Execute /Z "ModifyTable alignment( " + df + "VarName )=0, width( " + df + "VarName )=100"
			Execute /Z "ModifyTable alignment( " + df + "Description )=0, width( " + df + "Description )=500"
			
			SetWindow $tableName hook=NMConfigEditHook
			
		endif
		
		DoWindow /F $tableName
		
		NMConfigCopy( fname, 1 ) // get current configuration values
		
		icnt = 0
	
		for ( ocnt = 0; ocnt < ItemsInList( varList ); ocnt += 1 )
			objName = StringFromList( ocnt, varList )
			VarName[ icnt ] = objName
			NumValue[ icnt ] = NumVarOrDefault( df+objName, Nan )
			StrValue[ icnt ] = blankStr
			Description[ icnt ] = StrVarOrDefault( df+"D_"+objName, "" )
			icnt += 1
		endfor
		
		icnt += 1
		
		for ( ocnt = 0; ocnt < ItemsInList( strList ); ocnt += 1 )
			objName = StringFromList( ocnt, strList )
			VarName[ icnt ] = objName
			StrValue[ icnt ] = StrVarOrDefault( df+objName,"" )
			Description[ icnt ] = StrVarOrDefault( df+"D_"+objName, "" )
			icnt += 1
		endfor
		
	endfor
	
	return 0

End // NMConfigEdit

//****************************************************************
//****************************************************************

Function NMConfigEditHook( infoStr )
	String infoStr
	
	Variable runhook
	
	String event = StringByKey( "EVENT",infoStr )
	String win = StringByKey( "WINDOW",infoStr )
	String prefix = "Config_"
	
	Variable icnt = StrSearch( win, prefix, 0, 2 )
	
	if ( icnt < 0 )
		return 0
	endif
	
	String fname = win[ icnt+strlen( prefix ),inf ]

	strswitch( event )
		case "deactivate":
			runhook = 1
			SetNMstr( NMDF+"ConfigHookEvent", "deactivate" )
			break
		case "kill":
			runhook = 1
			SetNMstr( NMDF+"ConfigHookEvent", "kill" )
			break
	endswitch
	
	if ( runhook == 1 )
		NMConfigEdit2Vars( fname )
		NMConfigCopy( fname, -1 ) // now save these to appropriate folder
		Execute /Z fname + "ConfigHook( )" // run particular tab hook if exists
	endif

End // NMConfigEditHook

//****************************************************************
//****************************************************************

Function NMConfigEdit2Vars( fname ) // save table values to config vars
	String fname // config folder name

	String objName, df = ConfigDF( fname )
	
	Variable icnt, jcnt, items, objNum
	String objStr, objList, vList
	
	String tableName = "Config_" + fname

	if ( WinType( tableName ) != 2 )
		return 0 // table doesnt exist
	endif
	
	if ( WaveExists( $( df+"VarName" ) ) == 0 )
		return 0
	endif
	
	Wave /T VarName = $( df+"VarName" )
	Wave /T Description = $( df+"Description" )
	
	vList = Wave2List( df+"VarName" )
	
	// save numeric variables
	
	objList = NMConfigVarList( fname, 2 )
	
	if ( WaveExists( $( df+"NumValue" ) ) == 1 )
	
		Wave NumValue = $( df+"NumValue" )
		
		items = numpnts( NumValue )
	
		for ( icnt = 0; icnt < items; icnt += 1 )
		
			objName = VarName[ icnt ]
	
			if ( ( strlen( objName ) == 0 ) || ( FindListItem( objName, objList ) < 0 ) )
				continue
			endif
			
			SetNMvar( df+objName, NumValue[ icnt ] )
			
			vList = RemoveFromList( objName, vList )
			
		endfor
	
	endif
	
	// save string variables
	
	objList = NMConfigVarList( fname, 3 )
	
	if ( WaveExists( $( df+"StrValue" ) ) == 1 )
	
		Wave /T StrValue = $( df+"StrValue" )
		
		items = numpnts( NumValue )
	
		for ( icnt = 0; icnt < items; icnt += 1 )
		
			objName = VarName[ icnt ]
			
			if ( ( strlen( objName ) == 0 ) || ( FindListItem( objName, objList ) < 0 ) )
				continue
			endif
			
			SetNMstr( df+objName, StrValue[ icnt ] )
			
			vList = RemoveFromList( objName, vList )
			
		endfor
	
	endif
	
	// check for remaining variables
	
	for ( icnt = 0; icnt < ItemsInList( vlist ); icnt += 1 )
	
		objName = StringFromList( icnt, vlist )
		
		if ( exists( df+objName ) > 0 )
			continue
		endif
		
		for ( jcnt = 0; jcnt < numpnts( VarName ); jcnt += 1 )
		
			if ( StringMatch( objName, VarName[ jcnt ] ) == 1 )
			
				objStr = StrValue[ jcnt ]
				objNum = NumValue[ jcnt ]
				
				if ( numtype( objNum ) == 0 )
					SetNMvar( df+objName, objNum )
				else
					SetNMstr( df+objName, objStr )
				endif
				
				SetNMstr( df+"D_"+objName, Description[ jcnt ] )
				
			endif
		
		endfor
		
	endfor
	
End // NMConfigEdit2Vars

//****************************************************************
//****************************************************************


