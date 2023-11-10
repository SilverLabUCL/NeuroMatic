#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//*********************************************
//*********************************************
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
//*********************************************
//*********************************************
//
//	Deprecated Functions
//
//	Functions listed here are no longer used
//	and should be replaced with the new functions provided.
//
//*********************************************
//*********************************************
//
//	GetGraphName conflicts with existing Igor procedure so removed completely (18 Feb 2011)
//	NMSetsSet conflicts with new Sets function (22 Sept 2012)
//	NMStatsHistogram was overwritten with new function using optional parameters (28 Jan 2013)
//	NMStatsSubfolderKill changed to have optional subfolder name (31 Jan 2013)
//	NMStatsSubfolderClear changed to have optional subfolder name (31 Jan 2013)
//	NMMainHistogram was overwritten with new function using optional parameters (10 Feb 2013)
//	NMScaleByNum was overwritten with function in NM_Utility.ipf
//
//*********************************************
//*********************************************

Function /S PackDF(fname)
	String fname
	
	NMDeprecatedAlert("NMPackageDF")
	
	return NMPackageDF(fname)
	
End // PackDF

//*********************************************

Function CheckPackDF(subfolderName)
	String subfolderName
	
	NMDeprecatedAlert("CheckNMPackageDF")
	
	return CheckNMPackageDF(subfolderName)
	
End // CheckPackDF

//*********************************************

Function CheckPackage(subfolderName, forceVariableCheck)
	String subfolderName
	Variable forceVariableCheck
	
	NMDeprecatedAlert("CheckNMPackage")
	
	return CheckNMPackage(subfolderName, forceVariableCheck)
	
End // CheckPackage

//*********************************************

Function ResetNMCall()

	NMDeprecatedAlert("ResetNM")
	
	return ResetNM(0, history=1)

End // ResetNMCall

//*********************************************

Function NMWinCascadeResetCall()

	NMDeprecatedAlert("NMSet")
	
	return NMSet(winCascade=0, history=1)

End // NMWinCascadeResetCall

//*********************************************

Function SetCascadeXY(windowName)
	String windowName
	
	NMDeprecatedAlert("NMWinCascade")
	
	return NMWinCascade(windowName)
	
End // SetCascadeXY

//*********************************************

Function ResetCascade()

	NMDeprecatedAlert("NMWinCascadeReset")
	
	return NMWinCascadeReset()
	
End // ResetCascade

//*********************************************

Function AddNMTab(tabName)
	String tabName
	
	NMDeprecatedAlert("NMTabAdd")
	
	return NMTabAdd(tabName, "")

End // AddNMTab

//*********************************************

Function /S NMTabsExisting()

	NMDeprecatedAlert("TabNameList")
	
	return TabNameList(NMTabControlList())

End // NMTabsExisting

//*********************************************

Function /S NMTabListGet()
	
	NMDeprecatedAlert("NMTabControlList")

	return NMTabControlList()

End // NMTabListGet

//*********************************************

Function NMConfigsCall(on)
	Variable on
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(configsDisplay=on, history=1)
	
End // NMConfigsCall

//*********************************************

Function NMConfigOpenCall()

	NMDeprecatedAlert("NMConfigOpen")
	
	return NMConfigOpen("", history=1)

End // NMConfigOpenCall

//*********************************************

Function NMConfigVarSetCall(tabName, varName, value)
	String tabName
	String varName
	Variable value
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet(tabName, varName, value, history=1)
	
End // NMConfigVarSetCall

//*********************************************

Function NMConfigStrSetCall(tabName, varName, strValue)
	String tabName
	String varName
	String strValue
	
	NMDeprecatedAlert("NMConfigStrSet")
	
	return NMConfigStrSet(tabName, varName, strValue, history=1)
	
End // NMConfigStrSetCall

//*********************************************

Function SetOpenDataPath()

	NMDeprecatedAlert("SetOpenDataPathCall")
	
	return SetOpenDataPathCall()

End // SetOpenDataPath

//*********************************************

Function SetSaveDataPath()
	
	NMDeprecatedAlert("SetSaveDataPathCall")
	
	return SetSaveDataPathCall()

End // SetSaveDataPath

//*********************************************

Function /S NMSubfolder(folderPrefix, wavePrefix, chanNum, waveSelect)
	String folderPrefix
	String wavePrefix
	Variable chanNum
	String waveSelect
	
	NMDeprecatedAlert("NMSubfolderName")
	
	return NMSubfolderName(folderPrefix, wavePrefix, chanNum, waveSelect)
	
End // NMSubfolder

//*********************************************

Function /S FolderNameCreate(fileName)
	String fileName
	
	NMDeprecatedAlert("NMFolderNameCreate")
	
	return NMFolderNameCreate(fileName, nmPrefix=0)

End // FolderNameCreate

//*********************************************

Function /S NMFolderPath(folderName)
	String folderName
	
	NMDeprecatedAlert("CheckNMFolderPath")
	
	return CheckNMFolderPath(folderName)
	
End // NMFolderPath

//*********************************************

Function /S NMCurrentFolder()

	NMDeprecatedAlert("CurrentNMFolder")

	return CurrentNMFolder(0)

End // NMCurrentFolder

//*********************************************

Function /S NMFolderCloseCurrent()

	NMDeprecatedAlert("NMFolderClose")

	NMFolderClose("")
	
End // NMFolderCloseCurrent

//*********************************************

Function NMFolderCloseAll()

	NMDeprecatedAlert("NMFolderClose")
	
	NMFolderClose("All")

End // NMFolderCloseAll

//*********************************************

Function /S NMFolderAppendAll()

	NMDeprecatedFatalError("")
	
	return "" // NOT FUNCTIONAL

End // NMFolderAppendAll

//*********************************************

Function NMFolderAppend()

	NMDeprecatedFatalError("NMFoldersMerge")
	
	return NaN // NOT FUNCTIONAL

End // NMFolderAppend

//*********************************************

Function NMFolderAppendWaves(fromFolder, toFolder, wavePrefix)
	String fromFolder
	String toFolder
	String wavePrefix
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // NMFolderAppendWaves

//*********************************************

Function NMFolderGlobalsSave(wavePrefix)
	String wavePrefix
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // NMFolderGlobalsSave

//*********************************************

Function NMFolderGlobalsGet(wavePrefix)
	String wavePrefix
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // NMFolderGlobalsGet

//*********************************************

Function /S CheckFolderNameChar(fname)
	String fname
	
	NMDeprecatedAlert("NMCheckStringName")
	
	return NMCheckStringName(fname)
	
End // CheckFolderNameChar

//*********************************************

Function PrintFileDetails()

	NMDeprecatedAlert("PrintNMFolderDetails")

	return PrintNMFolderDetails("")

End // PrintFileDetails

//*********************************************

Function /S FileBinOpen(dialogue, xxx, parentFolder, path, fileList, changeFolder)
	Variable dialogue
	Variable xxx // NOT USED
	String parentFolder
	String path
	String fileList
	Variable changeFolder
	
	NMDeprecatedAlert("NMFileBinOpen")
	
	String extStr = "?"
	
	return NMFileBinOpen(dialogue, extStr, parentFolder, path, fileList, changeFolder)
	
End // FileBinOpen

//*********************************************

Function /S NMFolderSave()

	NMDeprecatedAlert("NMFolderSaveToDisk")
	
	return NMFolderSaveToDisk()
	
End // NMFolderSave

//*********************************************

Function /S NMFolderOpenAll()

	NMDeprecatedAlert("NMFolderOpen")

	return NMFolderOpen()

End // NMFolderOpenAll

//*********************************************

Function /S FileBinOpenAll(dialogue, df, path)
	Variable dialogue
	String df
	String path
	
	String extStr = "?"
	String parentFolder = "root:"
	String filePathList = ""
	Variable changeFolder = 1
	
	NMDeprecatedAlert("NMFileBinOpen")
	
	return NMFileBinOpen(dialogue, extStr, parentFolder, path, filePathList, changeFolder)
	
End // FileBinOpenAll

//*********************************************

Function /S FileBinExt()

	NMDeprecatedAlert("")
	
	return ".pxp"

End // FileBinExt

//*********************************************

Function /S FileDialogue(dialogueType, pathname, file, ext)
	Variable dialogueType
	String pathname
	String file
	String ext

	if (dialogueType == 0)
	
		NMDeprecatedAlert("NMFileOpenDialogue")
		
		return NMFileOpenDialogue(pathname, ext)
		
	else
	
		NMDeprecatedAlert("NMFileSaveDialogue")
	
		return NMFileSaveDialogue(pathname, file, ext)
		
	endif

End // FileDialogue

//*********************************************

Function /S FileBinSave(dialogue, new, folder, path, extFile, closed, fileType)
	Variable dialogue
	Variable new
	String folder
	String path
	String extFile
	Variable closed
	Variable fileType
	
	NMDeprecatedAlert("NMFolderSaveToDisk")
	
	if (fileType == 0)
		return NMFolderSaveToDisk(folder=folder, extFile=extFile, fileType="NM", new=new, closed=closed, dialogue=dialogue, path=path)
	else
		return NMFolderSaveToDisk(folder=folder, extFile=extFile, fileType="Igor Binary", new=new, closed=closed, dialogue=dialogue, path=path)
	endif
	
End // FileBinSave

//*********************************************

Function /S IgorBinSave(folder, file)
	String folder
	String file
	
	NMDeprecatedAlert("NMFolderSaveToDisk")
	
	return NMFolderSaveToDisk(folder=folder, extFile=file, dialogue=0)
	
End // IgorBinSave

//*********************************************

Function /S NMBinSave(folder, file, writeFlag, closed)
	String folder
	String file
	String writeFlag
	Variable closed
	
	NMDeprecatedAlert("NMFolderSaveToDisk")
	
	return NMFolderSaveToDisk(folder=folder, extFile=file, closed=closed, nmbWriteFlag=writeFlag, dialogue=0)
	
End // NMBinSave

//*********************************************

Function NMBin2Igor(path, fileList)
	String path
	String fileList 
	
	NMDeprecatedAlert("NMBin2IgorBin")
	
	return NMBin2IgorBin(path, fileList)
	
End // NMBin2Igor

//*********************************************

Function ChanGraphMake(channel [ image ])
	Variable channel // (-1) for current channel
	Variable image // (0) Display 1D wave (1) Image 2D wave
	
	Variable waveNum = -1
	
	return NMChanGraphMake(channel=channel, waveNum=waveNum, image=image)
	
End // ChanGraphMake

//*********************************************

Function /S ChanGraphUpdate(channel, makeChanWave)
	Variable channel // (-1) for current channel
	Variable makeChanWave // (0) no (1) yes
	
	Variable waveNum = -1
	
	NMDeprecatedAlert("NMChanGraphUpdate")
	
	return NMChanGraphUpdate(channel=channel, waveNum=waveNum, makeChanWave=makeChanWave)
	
End // ChanGraphUpdate

//*********************************************

Function ChanOnCall(channel, on)
	Variable channel
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, on=on, history=1)
	
End // ChanOnCall

//*********************************************

Function ChanOn(channel , on)
	Variable channel
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, on=on)
	
End // ChanOn

//*********************************************

Function ChanOnAllCall()

	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=-2, on=1, history=1)

End // ChanOnAllCall

//*********************************************

Function ChanOnAll()

	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=-2, on=1)

End // ChanOnAll

//*********************************************

Function ChanAutoScaleCall(channel, on)
	Variable channel
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, autoscale=on, history=1)
	
End // ChanAutoScaleCall

//*********************************************

Function ChanAutoScale(channel, on)
	Variable channel
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, autoscale=on)

End // ChanAutoScale

//*********************************************

Function ChanAutoScaleX(channel, on)
	Variable channel
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, freezeY=on)

End // ChanAutoScaleX

//*********************************************

Function ChanAutoScaleY(channel, on)
	Variable channel
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, freezeX=on)

End // ChanAutoScaleY

//*********************************************

Function ChanAllX(xmin, xmax)
	Variable xmin, xmax
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=-2 , xmin=xmin, xmax=xmax)
	
End // ChanAllX

//*********************************************

Function ChanAllY(ymin, ymax)
	Variable ymin, ymax
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=-2 , ymin=ymin, ymax=ymax)
	
End // ChanAllY

//*********************************************

Function ChanXYSet(chan, xmin, xmax, ymin, ymax)
	Variable chan, xmin, xmax, ymin, ymax
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=-2 , xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax)

End // ChanXYSet

//*********************************************

Function ChanGraphsMove()

	NMDeprecatedAlert("ChanGraphMove")

	Variable channel = -2 // all channels

	return ChanGraphMove(channel)

End // ChanGraphsMove

//*********************************************

Function NMChanMarkersMode(channel [ prefixFolder ])
	Variable channel
	String prefixFolder
	
	NMDeprecatedFatalError("")
	
	return NaN
	
End // NMChanMarkersMode

//*********************************************

Function NMChanMarkersCall(channel)
	Variable channel
	
	NMDeprecatedFatalError("")
	
	return NaN
	
End // NMChanMarkersCall

//*********************************************

Function NMChanMarkers(channel, markers)
	Variable channel
	Variable markers
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	switch(markers)
		case 0:
			return NMChannelGraphSet(channel=channel, traceMode=0)
		case 1:
			return NMChannelGraphSet(channel=channel, traceMode=3)
		case 2:
			return NMChannelGraphSet(channel=channel, traceMode=4)
	endswitch
	
End // NMChanMarkers

//*********************************************

Function NMChanErrorsOn(channel, on)
	Variable channel
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, errors=on)
	
End // NMChanErrorsOn

//*********************************************

Function NMChanErrorLinesPointsLimit(channel, errorPointsLimit)
	Variable channel // NOT USED
	Variable errorPointsLimit
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(errorPointsLimit=errorPointsLimit)
	
End // NMChanErrorLinesPointsLimit

//*********************************************

Function ChanGrid(channel, on)
	Variable channel
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, grid=on)
	
End // ChanGrid

//*********************************************

Function ChanGridToggle(channel)
	Variable channel
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	String cdf = ChanDF(channel)
	
	if (strlen(cdf) == 0)
		return -1
	endif
	
	Variable grid = NumVarOrDefault(cdf + "Grid", 1)
	
	grid = BinaryInvert(grid)
	
	return NMChannelGraphSet(channel=channel, grid=grid)
	
End // ChanGridToggle

//*********************************************

Function NMDragOnCall(on)
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(drag=on, history=1)
	
End // NMDragOnCall

//*********************************************

Function NMDragOn(on)
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(drag=on)
	
End // NMDragOn

//*********************************************

Function NMDragOnToggle()

	NMDeprecatedAlert("NMChannelGraphSet")

	Variable on = BinaryInvert(NMVarGet("DragOn"))
	
	return NMChannelGraphSet(drag=on)
	
End // NMDragOnToggle

//*********************************************

Function ChanDragOn(on)
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(drag=on)
	
End // ChanDragOn

//*********************************************

Function ChanDragToggle()

	NMDeprecatedAlert("NMChannelGraphSet")
	
	Variable on = BinaryInvert(NMVarGet("DragOn"))
	
	return NMChannelGraphSet(drag=on)
	
End // ChanDragToggle

//*********************************************

Function ChanOverlayCall(channel, overlayNum)
	Variable channel, overlayNum
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, overlayNum=overlayNum, history=1)
	
End // ChanOverlayCall

//*********************************************

Function ChanOverlay(channel, overlayNum)
	Variable channel, overlayNum
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, overlayNum=overlayNum)
	
End // ChanOverlay

//*********************************************

Function ChanToFrontCall(channel, toFront)
	Variable channel, toFront
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, toFront=toFront, history=1)
	
End // ChanToFrontCall

//*********************************************

Function ChanToFront(channel, toFront)
	Variable channel
	Variable toFront
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, toFront=toFront)
	
End // ChanToFront

//*********************************************

Function ChanGraphsResetCoordinates()

	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=-2, reposition=1)

End // ChanGraphsResetCoordinates

//*********************************************

Function ChanGraphResetCoordinates(channel)
	Variable channel
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(channel=channel, reposition=1)

End // ChanGraphResetCoordinates

//*********************************************

Function ChanControlsDisable(channel, select)
	Variable channel
	String select
	
	NMDeprecatedAlert("NMChannelGraphDisable")
	
	select += "000000"
	
	Variable overlay =  str2num(select[ 0, 0 ]) // NOT USED
	Variable filter = str2num(select[ 1, 1 ])
	Variable transform = str2num(select[ 2, 2 ])
	Variable autoscale = str2num(select[ 3, 3 ])
	Variable popMenu = str2num(select[ 4, 4 ])
	
	if (channel == -1)
		channel = -2 // changed flag
	endif
	
	return NMChannelGraphDisable(channel=channel, filter=filter, transform=transform, autoscale=autoscale, popMenu=popMenu)
	
End // ChanControlsDisable

//*********************************************

Function /S ChanSmthProc(channel)
	Variable channel
	
	NMDeprecatedAlert("ChanFilterProc")
	
	return ChanFilterProc(channel)

End // ChanSmthProc

//*********************************************

Function /S ChanSmthDF(channel)
	Variable channel
	
	NMDeprecatedAlert("ChanFilterDF")
	
	return ChanFilterDF(channel)
	
End // ChanSmthDF

//*********************************************

Function ChanSmth(channel, smoothNum, smoothAlg)
	Variable channel, smoothNum
	String smoothAlg
	
	NMDeprecatedAlert("NMChannelFilterSet")
	
	return NMChannelFilterSet(channel=channel, smoothAlg=smoothAlg, smoothNum=smoothNum)

End // ChanSmth

//*********************************************

Function ChanSmthNumGet(channel) 
	Variable channel
	
	NMDeprecatedAlert("ChanFilterNumGet")
	
	return ChanFilterNumGet(channel)
	
End // ChanSmthNumGet

//*********************************************

Function ChanSmthNumCall(channel, smoothNum)
	Variable channel, smoothNum
	
	NMDeprecatedAlert("ChanFilterNumCall")
	
	Variable filterNum = smoothNum
	
	return ChanFilterNumCall(channel, filterNum)

End // ChanSmthNumCall

//*********************************************

Function ChanSmthNum(channel, smoothNum)
	Variable channel, smoothNum
	
	NMDeprecatedAlert("NMChannelFilterSet")
	
	return NMChannelFilterSet(channel=channel, smoothNum=smoothNum)

End // ChanSmthNum

//*********************************************

Function /S ChanSmthAlgAsk(channel)
	Variable channel
	
	NMDeprecatedAlert("ChanFilterAlgAsk")
	
	return ChanFilterAlgAsk(channel)

End // ChanSmthAlgAsk

//*********************************************

Function /S ChanSmthAlgGet(channel)
	Variable channel

	NMDeprecatedAlert("ChanFilterAlgGet")

	return ChanFilterAlgGet(channel)

End // ChanSmthAlgGet

//*********************************************

Function ChanSmthUpdate(channel)
	Variable channel
	
	NMDeprecatedAlert("NMChanFilterSetVariableUpdate")
	
	return NMChanFilterSetVariableUpdate(channel)
	
End // ChanSmthUpdate

//*********************************************

Function ChanFilterFxnExists()

	NMDeprecatedAlert("exists")

	if (exists("FilterIIR") == 4)
		return 1
	endif
	
	return 0
	
End // ChanFilterFxnExists

//*********************************************

Function ChanFilter(channel, filterAlg, filterNum)
	Variable channel
	String filterAlg
	Variable filterNum
	
	NMDeprecatedAlert("MChannelFilterSet")
	
	if ((numtype(filterNum) > 0) || (filterNum <= 0))
		return NMChannelFilterSet(channel=channel, off=1)
	endif
	
	strswitch(filterAlg)
	
		case "binomial": // smooth
		case "boxcar": // smooth
			return NMChannelFilterSet(channel=channel, smoothAlg=filterAlg, smoothNum=filterNum)
			
		case "low-pass": // filter FIR
			return NMChannelFilterSet(channel=channel, lowPass=filterNum)
			
		case "high-pass": // filter FIR
			return NMChannelFilterSet(channel=channel, highPass=filterNum)
			
		default:
			return NMChannelFilterSet(channel=channel, off=1)
			
	endswitch
	
End // ChanFilter

//*********************************************

Function ChanPopupUpdate(chanNum)
	Variable chanNum
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // ChanPopupUpdate

//*********************************************

Function ChanWavesCount(chanNum)
	Variable chanNum
	
	NMDeprecatedAlert("NMWaveSelectCount")

	return NMWaveSelectCount(chanNum)

End // ChanWavesCount

//*********************************************

Function /S ChanLabel(chanNum, xy, wList)
	Variable chanNum
	String xy
	String wList
	
	NMDeprecatedAlert("NMChanLabel")
	
	// also see NMChanLabelX and NMChanLabelY
	
	return NMChanLabel(chanNum, xy, wList)
	
End // ChanLabel

//*********************************************

Function ChanLabelSet(chanNum, wSelect, xy, labelStr)
	Variable chanNum
	Variable wSelect
	String xy
	String labelStr
	
	NMDeprecatedAlert("NMChanLabelSet")
	
	return NMChanLabelSet(chanNum, wSelect, xy, labelStr)
	
End // ChanLabelSet

//*********************************************

Function /S GetWaveUnits(xy, wList, defaultLabel)
	String xy
	String wList
	String defaultLabel // NOT USED
	
	NMDeprecatedAlert("NMWaveUnitsList")
	
	return NMWaveUnitsList(xy, wList)
	
End // GetWaveUnits

//*********************************************

Function NMChanXLabelSetAllCall(xLabel)
	String xLabel
	
	NMDeprecatedAlert("NMChanXLabelSetAll")

	return NMChanXLabelSetAll(xLabel, history=1)

End // NMChanXLabelSetAllCall

//*********************************************

Function NMChanSelectCall(chanStr)
	String chanStr
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(chanSelect=chanStr, history=1)
	
End // NMChanSelectCall

//*********************************************

Function /S ChanCharList(numchans, seperator)
	Variable numchans
	String seperator
	
	NMDeprecatedAlert("NMChanList")
	
	return NMChanList("CHAR")
	
End // ChanCharList

//*********************************************

Function /S GetChanWaveName(chanNum, waveNum)
	Variable chanNum
	Variable waveNum
	
	NMDeprecatedAlert("NMChanWaveName")

	return NMChanWaveName(chanNum, waveNum)

End // GetChanWaveName

//*********************************************

Function /S ChanWaveName(chanNum, waveNum)
	Variable chanNum
	Variable waveNum
	
	NMDeprecatedAlert("NMChanWaveName")

	return NMChanWaveName(chanNum, waveNum)

End // ChanWaveName

//*********************************************

Function ChanWaveNum(wName)
	String wName
	
	NMDeprecatedAlert("NMChanWaveNum")
	
	return NMChanWaveNum(wName)
	
End // ChanWaveNum

//*********************************************

Function ChanWaveListSet(chanNum, force)
	Variable chanNum
	Variable force
	
	NMDeprecatedAlert("NMChanWaveListSet")
	
	return NMChanWaveListSet(force)
	
End // ChanWaveListSet

//*********************************************

Function ChanWaveListSort(chanNum, sortOption)
	Variable chanNum
	Variable sortOption
	
	NMDeprecatedAlert("NMChanWaveListSort")
	
	return NMChanWaveListSort(chanNum, sortOption)
	
End // ChanWaveListSort

//*********************************************

Function /S ChanWaveListSearch(wavePrefix, chanNum)
	String wavePrefix
	Variable chanNum
	
	NMDeprecatedAlert("NMChanWaveListSearch")
	
	return NMChanWaveListSearch(wavePrefix, chanNum)
	
End // ChanWaveListSearch

//*********************************************

Function CurrentChanSet(chanNum)
	Variable chanNum
	
	String chanStr
	
	NMDeprecatedAlert("NMChanSelect")
	
	if (chanNum < 0)
		chanStr = "All"
	else
		chanStr = num2istr(chanNum)
	endif
	
	return NMChanSelect(chanStr)
	
End // CurrentChanSet

//*********************************************

Function /S NMChanWaveListGet(chanNum) 
	Variable chanNum
	
	NMDeprecatedAlert("NMChanWaveList")
	
	return NMChanWaveList(chanNum)
	
End // NMChanWaveListGet

//*********************************************

Function /S ChanWaveListGet(chanNum) 
	Variable chanNum
	
	NMDeprecatedAlert("NMChanWaveList")
	
	return NMChanWaveList(chanNum)
	
End // ChanWaveListGet

//*********************************************

Function /S CurrentChanDisplayWave()

	NMDeprecatedAlert("ChanDisplayWave")
	
	return ChanDisplayWave(-1)
	
End // CurrentChanDisplayWave

//*********************************************

Function /S GetChanWaveList(chanNum) 
	Variable chanNum
	
	NMDeprecatedAlert("NMWaveSelectList")

	return NMWaveSelectList(chanNum)
	
End // GetChanWaveList

//*********************************************

Function /S GetWaveList()

	NMDeprecatedAlert("NMWaveSelectList")

	return NMWaveSelectList(-1)
	
End // GetWaveList

//*********************************************

Function UpdateNMWaveSelectLists()
	
	NMDeprecatedAlert("NMWaveSelectListMaster")
	
	NMWaveSelectListMaster(updateNM=1)
	
End // UpdateNMWaveSelectLists

//*********************************************

Function /S CurrentChanWaveList()

	NMDeprecatedAlert("NMWaveSelectList")

	return NMWaveSelectList(-1)

End // CurrentChanWaveList

//*********************************************

Function ChanSubfolderDefaultsSet(chanNum)
	Variable chanNum
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // ChanSubfolderDefaultsSet

//*********************************************

Function /S ChanFuncList()

	NMDeprecatedAlert("NMChanTransformList")

	return NMChanTransformList

End // ChanFuncList

//*********************************************

Function ChanFuncGet(chanNum)
	Variable chanNum
	
	NMDeprecatedFatalError("NMChanTransformGet")
	
	return NaN
	
End // ChanFuncGet

//*********************************************

Function /S ChanFuncNum2Name(select)
	Variable select
	
	NMDeprecatedFatalError("")
	
	return "" // NOT FUNCTIONAL
	
End // ChanFuncNum2Name

//*********************************************

Function /S ChanFuncGetName(chanNum)
	Variable chanNum
	
	NMDeprecatedAlert("NMChanTransformGet")

	return NMChanTransformGet(chanNum)

End // ChanFuncGetName

//*********************************************

Function ChanFuncCall(chanNum, on)
	Variable chanNum
	Variable on
	
	NMDeprecatedAlert("NMChanTransformCall")
	
	String returnStr = NMChanTransformCall(chanNum, on)
	
	return 0
	
End // ChanFuncCall

//*********************************************

Function ChanFuncAsk(chanNum)
	Variable chanNum
	
	NMDeprecatedFatalError("NMChanTransformAsk")
	
	return NaN // NOT FUNCTIONAL
	
End // ChanFuncAsk

//*********************************************

Function ChanFunc(chanNum, ft)
	Variable chanNum
	Variable ft
	
	String transform = NMChanTransformName(ft)
	
	NMDeprecatedAlert("NMChannelTransformSet")
	
	String returnStr = NMChannelTransformSet(channel=chanNum, transform=transform)
	
	return 0
	
End // ChanFunc

//*********************************************

Function ChanFuncNormAsk(chanNum)
	Variable chanNum
	
	NMDeprecatedAlert("NMChanTransformNormalizeCall")
	
	String returnStr = NMChanTransformNormalizeCall(chanNum)
	
	return 0
	
End // ChanFuncNormAsk

//*********************************************

Function NMChanFuncNormalize(channel, fxn1, xbgn1, xend1, fxn2, xbgn2, xend2)
	Variable channel
	String fxn1
	Variable xbgn1, xend1
	String fxn2
	Variable xbgn2, xend2
	
	Variable avgWin1, avgWin2
	
	STRUCT NMNormalizeStruct n
	NMNormalizeStructInit(n)
	
	if (StringMatch(fxn1[ 0, 5 ], "MinAvg"))
		fxn1 = "MinAvg"
		avgWin1 = str2num(fxn1[ 6, inf ])
	endif 
	
	n.fxn1 = fxn1
	n.avgWin1 = avgWin1
	n.xbgn1 = xbgn1
	n.xend1 = xend1
	n.minValue = 0
	
	if (StringMatch(fxn2[ 0, 5 ], "MaxAvg"))
		fxn2 = "MaxAvg"
		avgWin2 = str2num(fxn2[ 6, inf ])
	endif 
	
	n.fxn2 = fxn2
	n.avgWin2 = avgWin2
	n.xbgn2 = xbgn2
	n.xend2 = xend2
	n.maxValue = 1
	
	String returnStr = NMChanTransformNorm(channel=channel, n=n, deprecation=1)
	
	return 0
	
End // NMChanFuncNormalize

//*********************************************

Function /S NMChanTransformNormalize(channel, fxn1, xbgn1, xend1, fxn2, xbgn2, xend2)
	Variable channel
	String fxn1
	Variable xbgn1, xend1
	String fxn2
	Variable xbgn2, xend2
	
	Variable avgWin1, avgWin2
	
	STRUCT NMNormalizeStruct n
	NMNormalizeStructInit(n)
	
	if (StringMatch(fxn1[ 0, 5 ], "MinAvg"))
		fxn1 = "MinAvg"
		avgWin1 = str2num(fxn1[ 6, inf ])
	endif 
	
	n.fxn1 = fxn1
	n.avgWin1 = avgWin1
	n.xbgn1 = xbgn1
	n.xend1 = xend1
	n.minValue = 0
	
	if (StringMatch(fxn2[ 0, 5 ], "MaxAvg"))
		fxn2 = "MaxAvg"
		avgWin2 = str2num(fxn2[ 6, inf ])
	endif 
	
	n.fxn2 = fxn2
	n.avgWin2 = avgWin2
	n.xbgn2 = xbgn2
	n.xend2 = xend2
	n.maxValue = 1
	
	return NMChanTransformNorm(channel=channel, n=n, deprecation=1)
	
End // NMChanTransformNormalize

//*********************************************

Function ChanFuncDFOFAsk(chanNum)
	Variable chanNum
	
	NMDeprecatedAlert("NMChanTransformDFOFCall")
	
	String returnStr = NMChanTransformDFOFCall(chanNum)
	
	return 0
	
End // ChanFuncDFOFAsk

//*********************************************

Function NMChanFuncDFOF(chanNum, tbgn, tend)
	Variable chanNum
	Variable tbgn, tend
	
	NMDeprecatedAlert("NMChanTransformDFOF")
	
	String returnStr = NMChanTransformDFOF(chanNum, tbgn, tend)
	
	return 0
	
End // NMChanFuncDFOF

//*********************************************

Function ChanFuncBslnAsk(chanNum)
	Variable chanNum

	NMDeprecatedAlert("NMChanTransformBaselineCall")
	
	String returnStr = NMChanTransformBaselineCall(chanNum)
	
	return 0

End // ChanFuncBslnAsk

//*********************************************

Function NMChanFuncBaseline(chanNum, tbgn, tend)
	Variable chanNum
	Variable tbgn, tend
	
	NMDeprecatedAlert("NMChanTransformBaseline")
	
	String returnStr = NMChanTransformBaseline(chanNum, tbgn, tend)
	
	return 0
	
End // NMChanFuncBaseline

//*********************************************

Function /S NMChanTransform(channel, transform)
	Variable channel
	String transform
	
	NMDeprecatedAlert("NMChannelTransformSet")
	
	return NMChannelTransformSet(channel=channel, transform=transform)
	
End // NMChanTransform

//*********************************************

Function /S NextWaveName(prefix, chanNum, overwrite) 
	String prefix
	Variable chanNum
	Variable overwrite
	
	NMDeprecatedAlert("NextWaveName2")
	
	String dataFolder = ""
	
	return NextWaveName2(dataFolder, prefix, chanNum, overwrite) 
	
End // NextWaveName

//*********************************************

Function NMComputerCall(dialogue)
	Variable dialogue
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // NMComputerCall

//*********************************************

Function NMComputerStats(computer, xPixels, yPixels)
	String computer
	Variable xPixels, yPixels
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // NMComputerStats

//*********************************************

Function CheckComputerXYpixels()

	NMDeprecatedFatalError("")

	return NaN // NOT FUNCTIONAL

End // CheckComputerXYpixels

//*********************************************

Function NMPixelsX()

	NMDeprecatedAlert("NMScreenPixelsX")

	return NMScreenPixelsX()

End // NMPixelsX

//*********************************************

Function NMPixelsY()

	NMDeprecatedAlert("NMScreenPixelsY")

	return NMScreenPixelsY()

End // NMPixelsY

//*********************************************

Function NMComputerPixelsX()
	
	NMDeprecatedAlert("NMScreenPixelsX")

	return NMScreenPixelsX()
	
End // NMComputerPixelsX

//*********************************************

Function NMComputerPixelsY()

	NMDeprecatedAlert("NMScreenPixelsY")

	return NMScreenPixelsY()
	
End / NMComputerPixelsY

//*********************************************

Function /S NMProgressString()

	NMDeprecatedAlert("NMStrGet")

	return NMStrGet("ProgressStr")

End // NMProgressString

//*********************************************

Function NMProgressStr(progStr)
	String progStr
	
	NMDeprecatedAlert("SetNMstr")

	return SetNMstr(NMDF+"ProgressStr", progStr)

End // NMProgressStr

//*********************************************

Function NMProgressXYCall(xpixels, ypixels)
	Variable xpixels, ypixels
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(xProgress=xpixels, yProgress=ypixels, history=1)

End // NMProgressXYCall

//*********************************************

Function ResetProgress()

	NMDeprecatedAlert("NMProgressKill")

	return NMProgressKill()
	
End // ResetProgress

//*********************************************

Function CallNMProgress(currentCount, maxIterations)
	Variable currentCount, maxIterations
	
	String progressStr = NMStrGet("ProgressStr")
	
	NMDeprecatedAlert("NMProgress")
	
	return NMProgress(currentCount, maxIterations, progressStr)
	
End // CallNMProgress

//*********************************************

Function CallProgress(fraction)
	Variable fraction

	NMDeprecatedAlert("NMProgressCall")

	return NMProgressCall(fraction, NMStrGet("ProgressStr"))

End // CallProgress

//*********************************************

Function NMOverWriteOn(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Main", "OverwriteMode", on)

End // NMOverWriteOn

//*********************************************

Function NMOverWrite()

	NMDeprecatedFatalError("")

	return NaN // NOT FUNCTIONAL

End // NMOverWrite

//*********************************************

Function NMCurrentChan()

	NMDeprecatedAlert("CurrentNMChannel")
	
	return CurrentNMChannel()

End // CurrentNMChannel()

//*********************************************

Function /S NMCurrentChanStr()

	NMDeprecatedAlert("CurrentNMChanChar")

	return CurrentNMChanChar()

End // NMCurrentChanStr

//*********************************************

Function NMCurrentWaveCall(waveNum)
	Variable waveNum
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(waveNum=waveNum, history=1)
	
End // NMCurrentWaveCall

//*********************************************

Function NMCurrentWaveSetCall(waveNum)
	Variable waveNum
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(waveNum=waveNum, history=1)
	
End // NMCurrentWaveSetCall

//*********************************************

Function NMCurrentWaveSetNoUpdate(waveNum)
	Variable waveNum
	
	NMDeprecatedAlert("NMCurrentWaveSet")
	
	return NMCurrentWaveSet(waveNum, update=0)
	
End // NMCurrentWaveSet

//*********************************************

Function NMCurrentWave()

	NMDeprecatedAlert("CurrentNMWave")
	
	return CurrentNMWave()

End // NMCurrentWave

//*********************************************

Function /S CurrentWaveName()

	NMDeprecatedAlert("CurrentNMWaveName")

	return CurrentNMWaveName()

End // CurrentWaveName

//*********************************************

Function /S NMCurrentWavePrefix()

	NMDeprecatedAlert("CurrentNMWavePrefix")

	return CurrentNMWavePrefix()

End // NMCurrentWavePrefix

//*********************************************

Function /S NMWavePrefix()

	NMDeprecatedAlert("NMStrGet")

	return NMStrGet("WavePrefix")
	
End // NMWavePrefix

//*********************************************

Function /S NMWaveSelectDefaults()

	NMDeprecatedFatalError("")

	return "" // NOT FUNCTIONAL
	
End // NMWaveSelectDefaults

//*********************************************

Function NMCurrentTab()

	NMDeprecatedAlert("NMVarGet")

	return NMVarGet("CurrentTab")

End // NMCurrentTab

//*********************************************

Function /S NMTabCurrent()

	NMDeprecatedAlert("CurrentNMTabName")

	return CurrentNMTabName()

End // NMTabCurrent

//*********************************************

Function MakeNMPanelCall()

	NMDeprecatedAlert("MakeNMPanel")
	
	return MakeNMPanel(history=1)

End // MakeNMPanelCall

//*********************************************

Function UpdateNMFolderMenu()

	NMDeprecatedAlert("UpdateNMPanelFolderMenu")

	return UpdateNMPanelFolderMenu()
	
End // UpdateNMFolderMenu

//*********************************************

Function UpdateNMGroupMenu()

	NMDeprecatedAlert("UpdateNMPanelGroupMenu")

	return UpdateNMPanelGroupMenu()

End // UpdateNMGroupMenu

//*********************************************

Function UpdateNMSetVar()

	NMDeprecatedAlert("UpdateNMPanelSetVariables")

	return UpdateNMPanelSetVariables()

End // UpdateNMSetVar

//*********************************************

Function UpdateNMPrefixMenu()

	NMDeprecatedAlert("UpdateNMPanelPrefixMenu")

	return UpdateNMPanelPrefixMenu()

End // UpdateNMPrefixMenu

//*********************************************

Function UpdateNMChanSelect()

	NMDeprecatedAlert("UpdateNMPanelChanSelect")

	return UpdateNMPanelChanSelect()

End // UpdateNMChanSelect

//*********************************************

Function UpdateNMWaveSelect()

	NMDeprecatedAlert("UpdateNMPanelWaveSelect")

	return UpdateNMPanelWaveSelect()

End // UpdateNMWaveSelect

//*********************************************

Function NMPrefixPrompt(on)
	Variable on
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(PrefixSelectPrompt=on)
	
End // NMPrefixPrompt

//*********************************************

Function NMPrefixSelectCall(wavePrefix)
	String wavePrefix
	
	NMDeprecatedAlert("NMSet")
	
	NMSet(wavePrefix=wavePrefix, history=1)

End // NMPrefixSelectCall

//*********************************************

Function NMPrefixSelectSilent(wavePrefix)
	String wavePrefix
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(wavePrefixNoPrompt=wavePrefix)

End // NMPrefixSelectSilent

//*********************************************

Function NMPrefixSelectPrompt(PrefixSelectPrompt)
	Variable PrefixSelectPrompt
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(PrefixSelectPrompt=PrefixSelectPrompt)
	
End // NMPrefixSelectPrompt

//*********************************************

Function NMPrefixListClearCall()

	NMDeprecatedAlert("NMPrefixListClear")
	
	return NMPrefixListClear(history=1)

End // NMPrefixListClearCall

//*********************************************

Function NMNextWaveCall(direction)
	Variable direction
	
	NMDeprecatedAlert("NMNextWave")
	
	return NMNextWave(direction, history=1)
	
End // NMNextWaveCall

//*********************************************

Function NMGroupsOn(on)
	Variable on
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(on=BinaryCheck(on))
	
End // NMGroupsOn

//*********************************************

Function NMGroupsOnToggle()

	NMDeprecatedAlert("NMGroupsSet")

	Variable on = BinaryInvert(NMVarGet("GroupsOn"))
	
	NMGroupsSet(on=on)
	
	return on
	
End // NMGroupsOnToggle

//*********************************************

Function NMGroupFirst()

	NMDeprecatedAlert("NMGroupsFirst")

	return NMGroupsFirst("")

End // NMGroupFirst

//*********************************************

Function NMGroupLast()
	
	NMDeprecatedAlert("NMGroupsLast")
	
	return NMGroupsLast("")

End // NMGroupLast

//*********************************************

Function NMGroupGet(waveNum)
	Variable waveNum
	
	NMDeprecatedAlert("NMGroupsNum")
	
	return NMGroupsNum(waveNum)
	
End // NMGroupGet

//*********************************************

Function NMGroupsEdit()

	NMDeprecatedAlert("NMGroupsPanel")

	return NMGroupsPanel()
	
End // NMGroupsEdit

//*********************************************

Function /S NMGroupList(type)
	Variable type
	
	NMDeprecatedAlert("NMGroupsList")
	
	return NMGroupsList(type)

End // NMGroupList

//*********************************************

Function NMGroupSet(waveNum, group)
	Variable waveNum
	Variable group
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(waveNum=waveNum, group=group)
	
End // NMGroupSet

//*********************************************

Function NMGroupSeqDefault()

	NMDeprecatedAlert("NMGroupsSet")
	
	Variable numGroups = NMGroupsNumDefault()
	
	NMGroupsSet(numGroups=numGroups)

End // NMGroupSeqDefault

//*********************************************

Function /S NMGroupsSequenceBasic(numGroups)
	Variable numGroups

	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(numGroups=numGroups)

End // NMGroupsSequenceBasic

//*********************************************

Function NMGroupAssignCall(group)
	Variable group
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(group=group, history=1)
	
End // NMGroupAssignCall

//*********************************************

Function NMGroupsAssignCall(group)
	Variable group
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(group=group, history=1)
	
End // NMGroupsAssignCall

//*********************************************

Function NMGroupAssign(waveNum, group)
	Variable waveNum
	Variable group
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(waveNum=waveNum, group=group)
	
End // NMGroupAssign

//*********************************************

Function NMGroupsAssign(waveNum, group)
	Variable waveNum
	Variable group
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(waveNum=waveNum, group=group)
	
End // NMGroupsAssign

//*********************************************

Function NMGroupsDefineCall()

	NMDeprecatedAlert("NMGroupsCall")
	
	NMGroupsCall("Define", "")
	
End // NMGroupsDefineCall

//*********************************************

Function NMGroupSeqCall(groupSeq, fromWave, toWave, blocks)
	String groupSeq
	Variable fromWave, toWave, blocks
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(groupSeq=groupSeq, fromWave=fromWave, toWave=toWave, blocks=blocks, clearFirst=1)
	
End // NMGroupSeqCall

//*********************************************

Function /S NMGroupsSequenceCall(groupSeq, fromWave, toWave, blocks, clearFirst)
	String groupSeq
	Variable fromWave, toWave, blocks, clearFirst
	
	NMDeprecatedAlert("NMGroupsSet")
	
	return NMGroupsSet(groupSeq=groupSeq, fromWave=fromWave, toWave=toWave, blocks=blocks, clearFirst=clearFirst)
	
End // NMGroupsSequenceCall

//*********************************************

Function /S NMGroupsSequence(groupSeq, fromWave, toWave, blocks, clearFirst)
	String groupSeq
	Variable fromWave
	Variable toWave
	Variable blocks
	Variable clearFirst
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(groupSeq=groupSeq, fromWave=fromWave, toWave=toWave, blocks=blocks, clearFirst=clearFirst)
	
	return ""
	
End // NMGroupsSequence

//*********************************************

Function NMGroupsClearNoUpdate()

	NMDeprecatedAlert("NMGroupsClear")
	
	return NMGroupsClear(update=0)
			
End // NMGroupsClearNoUpdate

//*********************************************

Function NMGroupSeq(groupSeq, fromWave, toWave, blocks)
	String groupSeq
	Variable fromWave
	Variable toWave
	Variable blocks
	
	NMDeprecatedAlert("NMGroupsSet")
	
	NMGroupsSet(groupSeq=groupSeq, fromWave=fromWave, toWave=toWave, blocks=blocks, clearFirst=1)
	
End // NMGroupSeq

//*********************************************

Function NMGroupsTable(option)
	Variable option
	
	NMDeprecatedAlert("NMGroupsPanel")

	return NMGroupsPanel()
	
End // NMGroupsTable

//*********************************************

Function NMGroupsAreOn()
	
	NMDeprecatedAlert("NMVarGet")
	
	return NMVarGet("GroupsOn")
	
End // NMGroupsAreOn

//*********************************************

Function NMGroupsPanelCall()

	NMDeprecatedAlert("NMGroupsPanel")

	return NMGroupsPanel(history=1)

End // NMGroupsPanelCall

//*********************************************

Function UpdateNMSets(recount)
	Variable recount
	
	NMDeprecatedAlert("UpdateNMPanelSets")
	
	NMWaveSelectListMaster(updateNM=1)
	UpdateNMPanelSets(recount)
	
	return 0
	
End // UpdateNMSets

//*********************************************

Function NMSetsTable(option)
	Variable option
	
	NMDeprecatedAlert("NMSetsPanel")
	
	return NMSetsPanel()
	
End // NMSetsTable

//*********************************************

Function NMSetsPanelCall()

	NMDeprecatedAlert("NMSetsPanel")
	
	return NMSetsPanel(history=1)

End // NMSetsPanelCall

//*********************************************

Function NMSetsEqLockTableEditCall()

	NMDeprecatedAlert("NMSetsEqLockTableEdit")

	return NMSetsEqLockTableEdit(history=1)

End // NMSetsEqLockTableEditCall

//*********************************************

Function NMSetsEqLockTablePrintCall()

	NMDeprecatedAlert("NMSetsEqLockTablePrint")

	return NMSetsEqLockTablePrint(history=1)

End // NMSetsEqLockTablePrintCall

//*********************************************

Function NMSetsAssign(setList, waveNum, value [ prefixFolder, update ])
	String setList
	Variable waveNum
	Variable value
	String prefixFolder
	Variable update
	
	NMDeprecatedAlert("NMSetsSet")
	
	if (ParamIsDefault(prefixFolder))
		prefixFolder = ""
	endif
	
	return NMSetsSet(setList=setList, value=value, waveNum=waveNum, prefixFolder=prefixFolder)
	
End // NMSetsAssign

//*********************************************

Function NMSetsDataNew()

	NMDeprecatedFatalError("")

	return NaN // NOT FUNCTIONAL
	
End // NMSetsDataNew

//*********************************************

Function /S NMSetsDataList()

	NMDeprecatedFatalError("")

	return "" // NOT FUNCTIONAL

End // NMSetsDataList


//*********************************************

Function NMSetsEdit()

	NMDeprecatedAlert("NMSetsPanel")

	return NMSetsPanel()

End // NMsetsEdit


//*********************************************

Function UpdateNMSetsCount()

	NMDeprecatedAlert("UpdateNMSetsDisplayCount")

	return UpdateNMSetsDisplayCount()

End // UpdateNMSetsCount

//*********************************************

Function NMSetsZero2NanCall(setList)
	String setList
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL
	
End // NMSetsZero2NanCall

//*********************************************

Function NMSetsZero2Nan(setList)
	String setList
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL
	
End // NMSetsZero2Nan

//*********************************************

Function NMSetsNan2ZeroCall(setList)
	String setList
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // NMSetsNan2ZeroCall

//*********************************************

Function NMSetsNan2Zero(setList)
	String setList
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // NMSetsNan2Zero

//*********************************************

Function NMSetsFxnCall(setList)
	String setList
	
	NMDeprecatedAlert("NMSetsEquationCall")
	
	return NMSetsEquationCall()
	
End // NMSetsFxnCall

//*********************************************

Function NMSetsFxn(setList, arg, op)
	String setList
	String arg
	String op
	
	Variable icnt
	String setName, arg1, operation, arg2
	
	NMDeprecatedAlert("NMSetsEquation")
	
	for (icnt = 0 ; icnt < ItemsInList(setList) ; icnt += 1)
	
		setName = StringFromList(icnt, setList)
		
		strswitch(op)
		
			case "AND":
			case "OR":
				arg1 = setName
				operation = op
				arg2 = arg
				return NMSetsEquation(setName, arg1, operation, arg2)
				
			case "EQUALS":
				arg1 = arg
				operation = ""
				arg2 = ""
				return NMSetsEquation(setName, arg1, operation, arg2)
		
		endswitch
	
	endfor
	
	return -1

End // NMSetsFxn

//*********************************************

Function NMSetsAutoAdvance(on) // auto advance wave increment
	Variable on
	
	NMDeprecatedAlert("NMSetsSet")
	
	return NMSetsSet(autoWaveAdvance=on)
	
End // NMSetsAutoAdvance

//*********************************************

Function /S NMSetsRenameNoUpdate(setName, newName)
	String setName
	String newName
	
	NMDeprecatedAlert("NMSetsRename")
	
	return NMSetsRename(setName, newName, update=0)

End // NMSetsRenameNoUpdate

//*********************************************

Function NMSetsKillNoUpdate(setList)
	String setList
	
	NMDeprecatedAlert("NMSetsKill")
	
	return NMSetsKill(setList, update=0)

End // NMSetsKillNoUpdate

//*********************************************

Function NMSetsClearNoUpdate(setList)
	String setList
	
	NMDeprecatedAlert("NMSetsClear")
	
	return NMSetsClear(setList, update=0)

End // NMSetsClearNoUpdate

//*********************************************

Function /S NMSetsCopyNoUpdate(setName, newName)
	String setName, newName
	
	NMDeprecatedAlert("NMSetsCopy")
	
	return NMSetsCopy(setName, newName, update=0)
	
End // NMSetsCopyNoUpdate

//*********************************************

Function NMSetsInvertNoUpdate(setList)
	String setList
	
	NMDeprecatedAlert("NMSetsInvert")
	
	return NMSetsInvert(setList, update=0)
	
End // NMSetsInvertNoUpdate

//*********************************************

Function NMSetsConvertNoUpdate(wName, setName)
	String wName
	String setName
	
	NMDeprecatedAlert("NMSetsConvert")
	
	return NMSetsConvert(wName, setName, update=0)
	
End // NMSetsConvertNoUpdate

//*********************************************

Function /S NMSetsNewNoUpdate(setList)
	String setList
	
	NMDeprecatedAlert("NMSetsNew")
	
	return NMSetsNew(setList, update=0)
	
End // NMSetsNewNoUpdate

//*********************************************

Function NMSetsDefineNoUpdate(setList, value, first, last, skip, clearFirst)
	String setList
	Variable value
	Variable first
	Variable last
	Variable skip
	Variable clearFirst
	
	NMDeprecatedAlert("NMSetsDefine")
	
	return NMSetsDefine(setList, value, first, last, skip, clearFirst, update=0)
	
End // NMSetsDefineNoUpdate

//*********************************************

Function NMSetsEquationNoUpdate(setName, arg1, operation, arg2) // Set = arg1 AND arg2
	String setName
	String arg1
	String operation
	String arg2
	
	NMDeprecatedAlert("NMSetsEquation")
	
	return NMSetsEquation(setName, arg1, operation, arg2, update=0)
	
End // NMSetsEquationNoUpdate

//*********************************************

Function NMSetsEquationLockNoUpdate(setName, arg1, operation, arg2)
	String setName
	String arg1
	String operation
	String arg2
	
	NMDeprecatedAlert("NMSetsEquationLock")
	
	return NMSetsEquationLock(setName, arg1, operation, arg2, update =0)
	
End // NMSetsEquationLockNoUpdate

//*********************************************

Function /S NMCtrlName(prefix, ctrlName)
	String prefix
	String ctrlName
	
	NMDeprecatedAlert("ReplaceString")
	
	return ReplaceString(prefix, ctrlName, "")

End // NMCtrlName

//*********************************************

Function /S NMPrintWaveListCall()

	return NMMainCall("Print Names", "", deprecation=1)

End // NMPrintWaveListCall

//*********************************************

Function /S NMPrintWaveList()
	
	return NMMainWaveList(printToHistory=1, deprecation=1)

End // NMPrintWaveList

//*********************************************

Function /S NMPrintGroupWaveList()

	return NMMainWaveList(waveSelectList="All Groups", printToHistory=1, deprecation=1)

End // NMPrintGroupWaveList

//*********************************************

Function /S NMPrintWaveNotesCall()

	return NMMainCall("Print Notes", "", deprecation=1)

End // NMPrintWaveNotesCall

//*********************************************

Function /S NMPrintWaveNotes()

	return NMMainWaveNotes(deprecation=1)

End // NMPrintWaveNotes

//*********************************************

Function /S NMFindMissingSeqNumCall()

	return NMMainCall("Print Missing Seq #", "", deprecation=1)

End // NMFindMissingSeqNumCall

//*********************************************

Function /S NMDiffWavesCall(dtFlag)
	Variable dtFlag

	switch(dtFlag)
		case 1:
			return NMMainCall("Differentiate", "", deprecation=1)
		case 2:
			NMDeprecatedFatalError("NMMainDifferentiate")
			return "" // NOT FUNCTIONAL
		case 3:
			return NMMainCall("Integrate", "", deprecation=1)
	endswitch
	
End // NMDiffWavesCall

//*********************************************

Function /S NMDiffWaves(dtFlag)
	Variable dtFlag
	
	switch(dtFlag)
		case 1:
			return NMMainDifferentiate(deprecation=1)
		case 2:
			NMDeprecatedFatalError("NMMainDifferentiate")
			return "" // NOT FUNCTIONAL
		case 3:
			return NMMainIntegrate(deprecation=1)
	endswitch
	
End // NMDiffWaves

//*********************************************

Function /S DiffWaves(wList, dtFlag)
	String wList
	Variable dtFlag
	
	switch(dtFlag)
		case 1:
			return NMDifferentiate(wList, deprecation=1)
		case 2:
			NMDeprecatedFatalError("NMDifferentiate")
			return "" // NOT FUNCTIONAL
		case 3:
			return NMIntegrate(wList, deprecation=1)
	endswitch
	
End // DiffWaves

//*********************************************

Function /S NMDeleteNANsCall()

	return NMMainCall("Delete NANs", "", deprecation=1)

End // NMDeleteNANsCall

//*********************************************

Function /S NMDeleteNANs()

	return NMMainDeleteNaNs(deprecation=1)

End // NMDeleteNANs

//*********************************************

Function /S NMReplaceNanZeroCall(direction)
	Variable direction
	
	return NMMainCall("Replace Value", "", deprecation=1)

End // NMReplaceNanZeroCall

//*********************************************

Function /S NMReplaceNanZero(direction)
	Variable direction
	
	if (direction == 1)
		return NMMainReplaceValue(find=NaN, replacement=0, deprecation=1)
	elseif (direction == -1)
		return NMMainReplaceValue(find=0, replacement=NaN, deprecation=1)
	endif
	
End // NMReplaceNanZero

//*********************************************

Function /S NMReplaceWaveValueCall()

	return NMMainCall("Replace Value", "", deprecation=1)

End // NMReplaceWaveValueCall

//*********************************************

Function /S NMReplaceWaveValue(find, replacement)
	Variable find
	Variable replacement
	
	return NMMainReplaceValue(find=find, replacement=replacement, deprecation=1)
	
End // NMReplaceWaveValue

//*********************************************

Function /S NMSmoothWavesCall()

	return NMMainCall("Smooth", "", deprecation=1)

End // NMSmoothWavesCall

//*********************************************

Function /S NMSmoothWaves(algorithm, num)
	String algorithm
	Variable num
	
	return NMMainSmooth(algorithm=algorithm, num=num, deprecation=1)
	
End // NMSmoothWaves

//*********************************************

Function /S SmoothWaves(algorithm, num, wList)
	String algorithm
	Variable num
	String wList
	
	return NMSmooth(num, wList, algorithm=algorithm, deprecation=1)
	
End // SmoothWaves

//*********************************************

Function /S NMFilterFIRWavesCall()

	return NMMainCall("FilterFIR", "", deprecation=1)

End // NMFilterFIRWavesCall

//*********************************************

Function /S NMFilterFIRWaves(algorithm, f1, f2, n)
	String algorithm
	Variable f1, f2, n
	
	strswitch(algorithm)
		case "low-pass":
		case "high-pass":
			return NMMainFilterFIR(algorithm=algorithm, f1=f1, f2=f2, n=n, deprecation=1)
		case "notch":
			return NMMainFilterFIR(fc=f1, fw=f2, deprecation=1)
	endswitch
	
	return ""
	
End // NMFilterFIRWaves

//*********************************************

Function /S FilterFIRwaves(algorithm, f1, f2, n, wList)
	String algorithm
	Variable f1, f2, n
	String wList
	
	strswitch(algorithm)
		case "low-pass":
		case "high-pass":
			return NMFilterFIR(wList, algorithm=algorithm, f1=f1, f2=f2, n=n, deprecation=1)
		case "notch":
			return NMFilterFIR(wList, fc=f1, fw=f2, deprecation=1)
	endswitch

End // FilterFIRwaves

//*********************************************

Function /S NMFilterIIRWavesCall()

	return NMMainCall("FilterIIR", "", deprecation=1)
	
End // NMFilterIIRWavesCall

//*********************************************

Function /S NMFilterIIRWaves(algorithm, freqFraction, notchQ)
	String algorithm
	Variable freqFraction, notchQ
	
	strswitch(algorithm)
		case "low-pass":
			return NMMainFilterIIR(fLow=freqFraction, deprecation=1)
		case "high-pass":
			return NMMainFilterIIR(fHigh=freqFraction, deprecation=1)
		case "notch":
			return NMMainFilterIIR(fNotch=freqFraction, notchQ=notchQ, deprecation=1)
	endswitch
	
	return ""
	
End // NMFilterIIRWaves

//*********************************************

Function /S FilterIIRwaves(algorithm, freqFraction, notchQ, wList)
	String algorithm
	Variable freqFraction, notchQ
	String wList
	
	strswitch(algorithm)
		case "low-pass":
			return NMFilterIIR(wList, fLow=freqFraction, deprecation=1)
		case "high-pass":
			return NMFilterIIR(wList, fHigh=freqFraction, deprecation=1)
		case "notch":
			return NMFilterIIR(wList, fNotch=freqFraction, notchQ=notchQ, deprecation=1)
	endswitch
	
	return ""
	
End // FilterIIRwaves

//*********************************************

Function /S NMRotateWavesCall()

	return NMMainCall("Rotate", "", deprecation=1)

End // NMRotateWavesCall

//*********************************************

Function /S NMRotateWaves(points)
	Variable points
	
	return NMMainRotate(points=points, deprecation=1)
	
End // NMRotateWaves

//*********************************************

Function /S NMReverseWavesCall()

	return NMMainCall("Reverse", "", deprecation=1)

End // NMReverseWavesCall

//*********************************************

Function /S NMReverseWaves()

	return NMMainReverse(deprecation=1)

End // NMReverseWaves

//*********************************************

Function /S NMAlignWavesCall()

	return NMMainCall("Align", "", deprecation=1)

End // NMAlignWavesCall

//*********************************************

Function /S NMAlignWaves(waveOfAlignValues, positiveStartX)
	String waveOfAlignValues
	Variable positiveStartX
	
	Variable alignAtZero = BinaryInvert(positiveStartX)
	Variable alignAt = NMAlignAtValueOld(alignAtZero, waveOfAlignValues)
	
	return NMMainAlign(waveOfAlignValues=waveOfAlignValues, alignAt=alignAt, deprecation=1)
	
End // NMAlignWaves

//*********************************************

Function /S NMXScaleWaves(start, delta, npnts)
	Variable start
	Variable delta
	Variable npnts
	
	return NMMainSetScale(start=start, delta=delta, deprecation=1)
	
End // NMXScaleWaves

//*********************************************

Function /S NMXScaleWavesAll(start, delta, points)
	Variable start
	Variable delta
	Variable points
	
	String returnList1, returnList2
	
	if ((numtype(points) == 0) && (points >= 0))
		returnList1 = NMMainRedimension(points=points, deprecation=1)
	endif
	
	if ((numtype(start) == 0) || (numtype(delta) == 0))
		returnList2 = NMMainSetScale(start=start, delta=delta, deprecation=1)
	endif
	
	return NMAddToList(returnList1, returnList2, ";")
	
End // NMXScaleWavesAll

//*********************************************

Function /S NMStartXCall()

	return NMMainCall("StartX", "", deprecation=1)

End // NMStartXCall

//*********************************************

Function /S NMStartXAllCall(start)
	Variable start
	
	return NMMainSetScale(start=start, history=1, deprecation=1)
	
End // NMStartXAllCall

//*********************************************

Function /S NMStartX(start)
	Variable start
	
	return NMMainSetScale(start=start, deprecation=1)
	
End // NMStartX

//*********************************************

Function /S NMDeltaXCall()

	return NMMainCall("DeltaX", "", deprecation=1)

End // NMDeltaXCall

//*********************************************

Function /S NMDeltaX(delta)
	Variable delta
	
	return NMMainSetScale(delta=delta, deprecation=1)
	
End // NMDeltaX

//*********************************************

Function /S SetXScale(start, delta, points, wList)
	Variable start
	Variable delta
	Variable points
	String wList
	
	if (numtype(points) == 0)
		return NMRedimension(points, wList, deprecation=1)
	elseif ((numtype(start) == 0) || (numtype(delta) == 0))
		return NMSetScale(wList, start=start, delta=delta, deprecation=1)
	endif
	
End // SetXScale

//*********************************************

Function AlignByNum(setZeroAt, wList)
	Variable setZeroAt
	String wList
	
	NMSetScale(wList, start=-setZeroAt, deprecation=1)
	
End // AlignByNum

//*********************************************

Function /S NMNumPntsCall()

	return NMMainCall("Redimension", "", deprecation=1)

End // NMNumPntsCall

//*********************************************

Function /S NMNumPnts(points)
	Variable points
	
	return NMMainRedimension(points=points, deprecation=1)
	
End // NMNumPnts

//*********************************************

Function /S NMDeletePointsCall()

	return NMMainCall("Delete Points", "", deprecation=1)

End // NMDeletePointsCall

//*********************************************

Function /S NMDeletePoints(from, points)
	Variable from
	Variable points
	
	return NMMainDeletePoints(from=from, points=points, deprecation=1)
	
End // NMDeletePoints

//*********************************************

Function /S NMInsertPointsCall()

	return NMMainCall("Insert Points", "", deprecation=1)

End // NMInsertPointsCall

//*********************************************

Function /S NMInsertPoints(at, points, value)
	Variable at
	Variable points
	Variable value
	
	return NMMainInsertPoints(at=at, points=points, value=value, deprecation=1)
	
End // NMInsertPoints

//*********************************************

Function /S NMResampleWavesCall()

	return NMMainCall("Resample", "", deprecation=1)

End // NMResampleWavesCall

//*********************************************

Function /S NMResampleWaves(upSamples, downSamples, rate)
	Variable upSamples
	Variable downSamples
	Variable rate
	
	if ((numtype(rate) == 0) && (rate > 0))
		return NMMainResample(rate=rate, deprecation=1)
	elseif ((upSamples >= 1) && (downSamples >= 1))
		return NMMainResample(upSamples=upSamples, downSamples=downSamples, deprecation=1)
	else
		return ""
	endif
	
End // NMResampleWaves

//*********************************************

Function /S ResampleWaves(upSamples, downSamples, rate, wList)
	Variable upSamples
	Variable downSamples
	Variable rate
	String wList
	
	if ((numtype(rate) == 0) && (rate > 0))
		return NMResample(wList, rate=rate, deprecation=1)
	elseif ((upSamples >= 1) && (downSamples >= 1))
		return NMResample(wList, upSamples=upSamples, downSamples=downSamples, deprecation=1)
	else
		return ""
	endif
	
End // ResampleWaves

//*********************************************

Function /S NMDecimateWavesCall()

	return NMMainCall("Decimate", "", deprecation=1)

End // NMDecimateWavesCall

//*********************************************

Function /S NMDecimateWaves(downSamples)
	Variable downSamples
	
	return NMMainDecimate(downSamples=downSamples, deprecation=1)
	
End // NMDecimateWaves

//*********************************************

Function /S NMDecimate2DeltaXCall()

	return NMMainCall("Decimate", "", deprecation=1)
	
End // NMDecimate2DeltaXCall

//*********************************************

Function /S NMDecimate2DeltaX(newDeltaX)
	Variable newDeltaX
	
	return NMMainDecimate(rate=(1 / newDeltaX), deprecation=1)
	
End // NMDecimate2DeltaX

//*********************************************

Function /S DecimateWaves(downSamples, wList)
	Variable downSamples
	String wList
	
	return NMDecimate(wList, downSamples=downSamples, deprecation=1)
	
End // DecimateWaves

//*********************************************

Function /S Decimate2DeltaX(newDeltaX, wList)
	Variable newDeltaX
	String wList
	
	return NMDecimate(wList, rate=(1 / newDeltaX), deprecation=1)
	
End // Decimate2DeltaX

//*********************************************

Function /S NMInterpolateWavesCall()

	return NMMainCall("Interpolate", "", deprecation=1)

End // NMInterpolateWavesCall

//*********************************************

Function /S NMInterpolateWaves(algorithm, xmode, xWaveNew)
	Variable algorithm
	Variable xmode
	String xWaveNew
	
	if (xmode == 1)
		return NMMainInterpolate(algorithm=algorithm, xmode=1, deprecation=1)
	else
		return NMMainInterpolate(algorithm=algorithm, xmode=xmode, xWaveNew=xWaveNew, deprecation=1)
	endif
	
End // NMInterpolateWaves

//*********************************************

Function /S InterpolateWaves(algorithm, xmode, xwave, wList)
	Variable algorithm 
	Variable xmode
	String xwave
	String wList
	
	if (xmode == 1)
		return NMInterpolate(wList, algorithm=algorithm, xmode=1, deprecation=1)
	else
		return NMInterpolate(wList, algorithm=algorithm, xmode=xmode, xWave=xWave, deprecation=1)
	endif
	
End // InterpolateWaves

//*********************************************

Function /S NMTimeScaleModeCall(mode)
	Variable mode
	
	if (mode == 1)
		return NMMainCall("Continuous", "", deprecation=1)
	else
		return NMMainCall("Episodic", "", deprecation=1)
	endif

End // NMTimeScaleModeCall

//*********************************************

Function /S NMTimeScaleMode(mode)
	Variable mode
	
	if (mode == 1)
		return NMMainXScaleMode(mode="Continuous", deprecation=1)
	else
		return NMMainXScaleMode(mode="Episodic", deprecation=1)
	endif
	
End // NMTimeScaleMode

//*********************************************

Function /S NMXUnitsChangeCall(newUnits)
	String newUnits
	
	strswitch(newUnits)
		case "sec":
		case "msec":
		case "usec":
			return NMMainCall(newUnits, "", deprecation=1)
	endswitch
	
End // NMXUnitsChangeCall

//*********************************************

Function /S NMXUnitsChange(newUnits)
	String newUnits
	
	String oldUnits = StringFromList(0, NMChanXUnitsList())
	
	return NMMainTimeScaleConvert(oldUnits=oldUnits, newUnits=newUnits, history=1, deprecation=1)
	
End // NMXUnitsChange

//*********************************************

Function /S NMTimeUnitsConvertCall(newUnits)
	String newUnits
	
	strswitch(newUnits)
		case "sec":
		case "msec":
		case "usec":
			return NMMainCall(newUnits, "", deprecation=1)
	endswitch
	
End // NMTimeUnitsConvertCall

//*********************************************

Function /S NMTimeUnitsConvert(oldUnits, newUnits)
	String oldUnits
	String newUnits
	
	return NMMainTimeScaleConvert(oldUnits=oldUnits, newUnits=newUnits, history=1, deprecation=1)
	
End // NMTimeUnitsConvert

//*********************************************

Function /S NMMainXWaveMakeCall()

	return NMMainCall("Make X-scale Wave", "", deprecation=1)

End // NMMainXWaveMakeCall

//*********************************************

Function /S NMMakeCommonXwave(wList [ destWaveName ])
	String wList
	String destWaveName
	
	String prefix
	
	if (ParamIsDefault(destWaveName)) // create default destination wave name
	
		prefix = FindCommonPrefix(wList)
		
		if (strlen(prefix) > 0)
			destWaveName = NMXscalePrefix + prefix
		else
			destWaveName = NMXscalePrefix + StringFromList(0, wList)
		endif
		
	endif
	
	return NMXWaveMake(wList, xWave=destWaveName, deprecation=1)

End // NMMakeCommonXwave

//*********************************************

Function NMXvalueTransform(yWave, xValue, direction, lessORgreater)
	String yWave
	Variable xValue
	Variable direction
	Variable lessORgreater // NOT USED
	
	if (direction == 1)
		return NMXscaleTransform(xValue, "y2x", yWave=yWave, deprecation=1)
	elseif (direction == -1)
		return NMXscaleTransform(xValue, "x2y", yWave=yWave, deprecation=1)
	endif
	
End // NMXvalueTransform

//*********************************************

Function /S NMSortWavesByKeyWaveCall()

	return NMMainCall("Sort", "", deprecation=1)

End // NMSortWavesByKeyWaveCall

//*********************************************

Function /S NMSortWavesByKeyWave(sortKeyWave)
	String sortKeyWave
	
	return NMMainSort(sortKeyWave=sortKeyWave, deprecation=1)
	
End // NMSortWavesByKeyWave

//*********************************************

Function /S NMBaselineCall()

	return NMMainCall("Baseline", "", deprecation=1)

End // NMBaselineCall

//*********************************************

Function /S NMBslnWaves(xbgn, xend)
	Variable xbgn, xend
	
	return NMMainBaseline(xbgn=xbgn, xend=xend, deprecation=1)
	
End // NMBslnWaves

//*********************************************

Function /S NMBslnAvgWaves(xbgn, xend)
	Variable xbgn, xend
	
	return NMMainBaseline(xbgn=xbgn, xend=xend, allWavesAvg=1, deprecation=1)
	
End // NMBslnAvgWaves

//*********************************************

Function /S NMBaselineWaves(method, xbgn, xend)
	Variable method
	Variable xbgn, xend
	
	if (method == 2)
		return NMMainBaseline(xbgn=xbgn, xend=xend, allWavesAvg=1, deprecation=1)
	else
		return NMMainBaseline(xbgn=xbgn, xend=xend, deprecation=1)
	endif
	
End // NMBaselineWaves

//*********************************************

Function /S BaselineWaves(method, xbgn, xend, wList)
	Variable method
	Variable xbgn, xend
	String wList
	
	if (method == 2)
		return NMBaseline(wList, xbgn=xbgn, xend=xend, allWavesAvg=1, deprecation=1)
	else
		return NMBaseline(wList, xbgn=xbgn, xend=xend, deprecation=1)
	endif

End // BaselineWaves

//*********************************************

Function /S NMDFOFWavesCall()

	return NMMainCall("dF/Fo", "", deprecation=1)

End // NMDFOFWavesCall

//*********************************************

Function /S NMDFOFWaves(xbgn, xend)
	Variable xbgn, xend
	
	return NMMainBaseline(xbgn=xbgn, xend=xend, DFOF=1, deprecation=1)
	
End // NMDFOFWaves

//*********************************************

Function /S DFOFWaves(xbgn, xend, wList)
	Variable xbgn, xend
	String wList
	
	return NMBaseline(wList, xbgn=xbgn, xend=xend, DFOF=1, deprecation=1)

End // DFOFWaves

//*********************************************

Function /S NMAvgWavesCall()
	
	return NMMainCall("Average", "", deprecation=1)

End // NMAvgWavesCall

//*********************************************

Function /S NMAvgWaves(mode, graphInputs, chanTransforms, avgAllGroups, onePlot)
	Variable mode
	Variable graphInputs
	Variable chanTransforms
	Variable avgAllGroups
	Variable onePlot
	
	String selectList = "", all = ""
	
	STRUCT NMMatrixStatsStruct s
	
	s.xbgn = -inf
	s.xend = inf
	s.ignoreNANs = 1
	s.truncateToCommonXScale = 1
	s.saveMatrix = 0
	
	switch(mode)
		case 1:
			selectList = "avg"
			break
		case 2:
			selectList = "avg;stdv;"
			break
		case 3:
			selectList = "avg;sem;"
			break
		case 4:
			selectList = "avg;var;"
			break
		default:
			return ""
	endswitch
	
	if (avgAllGroups)
	
		if (onePlot)
			all = "All Groups"
		endif
		
		return NMMainMatrixStats(waveSelectList="All Groups", transforms=chanTransforms, selectList=selectList, s=s, graphInputs=graphInputs, all=all, deprecation=1)
		
	else
	
		return NMMainMatrixStats(transforms= chanTransforms, selectList=selectList, s=s, graphInputs=graphInputs, deprecation=1)
		
	endif
	
End // NMAvgWaves

//*********************************************

Function /S NMAvgWaves2(mode, ignoreNANs, graphInputs, chanTransforms, avgAllGroups, onePlot)
	Variable mode
	Variable ignoreNANs
	Variable graphInputs
	Variable chanTransforms
	Variable avgAllGroups
	Variable onePlot
	
	String selectList = "", all = ""
	
	STRUCT NMMatrixStatsStruct s
	
	s.xbgn = -inf
	s.xend = inf
	s.ignoreNANs = ignoreNANs
	s.truncateToCommonXScale = 1
	s.saveMatrix = 0
	
	switch(mode)
		case 1:
			selectList = "avg"
			break
		case 2:
			selectList = "avg;stdv;"
			break
		case 3:
			selectList = "avg;sem;"
			break
		case 4:
			selectList = "avg;var;"
			break
		default:
			return ""
	endswitch
	
	if (avgAllGroups)
	
		if (onePlot)
			all = "All Groups"
		endif
		
		return NMMainMatrixStats(waveSelectList="All Groups", transforms=chanTransforms, selectList=selectList, s=s, graphInputs=graphInputs, all=all, deprecation=1)
		
	else
	
		return NMMainMatrixStats(transforms=chanTransforms, selectList=selectList, s=s, graphInputs=graphInputs, deprecation=1)
		
	endif
	
End // NMAvgWaves2

//*********************************************

Function /S NMSumWavesCall()
	
	return NMMainCall("Sum", "", deprecation=1)

End // NMSumWavesCall

//*********************************************

Function /S NMSumWaves(graphInputs, chanTransforms, sumAllGroups, onePlot)
	Variable graphInputs
	Variable chanTransforms
	Variable sumAllGroups
	Variable onePlot
	
	String all = ""
	
	STRUCT NMMatrixStatsStruct s
	
	s.xbgn = -inf
	s.xend = inf
	s.ignoreNANs = 1
	s.truncateToCommonXScale = 1
	s.saveMatrix = 0
	
	if (sumAllGroups)
	
		if (onePlot)
			all = "All Groups"
		endif
		
		return NMMainMatrixStats(waveSelectList="All Groups", transforms=chanTransforms, selectList="sum", s=s, graphInputs=graphInputs, all=all, deprecation=1)
		
	else
	
		return NMMainMatrixStats(transforms=chanTransforms, selectList="sum", s=s, graphInputs=graphInputs, deprecation=1)
		
	endif

End // NMSumWaves

//*********************************************

Function /S NMWavesStats(mode, chanTransforms, ignoreNANs, truncateToCommonXScale, interpToSameDX, saveMatrix, graphInputs, onePlot)
	Variable mode
	Variable chanTransforms
	Variable ignoreNANs
	Variable truncateToCommonXScale
	Variable interpToSameDX // NOT USED
	Variable saveMatrix
	Variable graphInputs
	Variable onePlot
	
	String selectList
	
	STRUCT NMMatrixStatsStruct s
	
	s.xbgn = -inf
	s.xend = inf
	s.ignoreNANs = ignoreNANs
	s.truncateToCommonXScale = truncateToCommonXScale
	s.saveMatrix = saveMatrix
	
	switch(mode)
		case 1:
			selectList = "avg"
			break
		case 2:
			selectList = "avg;stdv;"
			break
		case 3:
			selectList = "avg;sem;"
			break
		case 4:
			selectList = "avg;var;"
			break
		case 5:
			selectList = "sum"
			break
		case 6:
			selectList = "sumsqrs"
			break
		default:
			return ""
	endswitch
	
	return NMMainMatrixStats(transforms=chanTransforms, selectList=selectList, s=s, graphInputs=graphInputs, deprecation=1)
	
End // NMWavesStats

//*********************************************

Function /S NMNormWaves(fxn, xbgn, xend, baselineXbgn, baselineXend)
	String fxn
	Variable xbgn, xend
	Variable baselineXbgn, baselineXend
	
	String fxn1 = "avg"
	Variable xbgn1 = baselineXbgn
	Variable xend1 = baselineXend
	
	String fxn2 = fxn
	Variable xbgn2 = xbgn
	Variable xend2 = xend
	
	return NMMainNormalize(fxn1=fxn1, xbgn1=xbgn1, xend1=xend1, fxn2=fxn2, xbgn2=xbgn2, xend2=xend2, minValue=0, maxValue=1, deprecation=1)
	
End // NMNormWaves

//*********************************************

Function /S NMNormalizeWavesCall()

	return NMMainCall("Normalize", "", deprecation=1)

End // NMNormalizeWavesCall

//*********************************************

Function /S NMNormalizeWaves(fxn1, xbgn1, xend1, fxn2, xbgn2, xend2)
	String fxn1
	Variable xbgn1, xend1
	String fxn2
	Variable xbgn2, xend2
	
	return NMMainNormalize(fxn1=fxn1, xbgn1=xbgn1, xend1=xend1, fxn2=fxn2, xbgn2=xbgn2, xend2=xend2, minValue=0, maxValue=1, deprecation=1)
	
End // NMNormalizeWaves

//*********************************************

Function /S NMBlankWavesCall()

	return NMMainCall("Clip Events", "", deprecation=1)
	
End // NMBlankWavesCall

//*********************************************

Function /S NMBlankWaves(waveOfEventTimes, xwinBeforeEvent, xwinAfterEvent [ blankValue ])
	String waveOfEventTimes
	Variable xwinBeforeEvent, xwinAfterEvent
	Variable blankValue
	
	return NMMainClipEvents(xwinBeforeEvent=xwinBeforeEvent, xwinAfterEvent=xwinAfterEvent, clipValue=blankValue, waveOfEventTimes=waveOfEventTimes, deprecation=1)
	
End // NMBlankWaves

//*********************************************

Function /S NMMainEventsClipCall()

	return NMMainCall("Clip Events", "", deprecation=1)

End // NMMainEventsClipCall

//*********************************************

Function /S NMMainEventsClip(positiveEvents, eventFindLevel, xwinBeforeEvent, xwinAfterEvent [ waveOfEventTimes, clipValue ])
	Variable positiveEvents
	Variable eventFindLevel
	Variable xwinBeforeEvent
	Variable xwinAfterEvent
	String waveOfEventTimes
	Variable clipValue
	
	if (ParamIsDefault(waveOfEventTimes))
		waveOfEventTimes = ""
	endif
	
	return NMMainClipEvents(positiveEvents=positiveEvents, eventFindLevel=eventFindLevel, xwinBeforeEvent=xwinBeforeEvent, xwinAfterEvent=xwinAfterEvent, clipValue=clipValue, waveOfEventTimes=waveOfEventTimes, deprecation=1)
	
End // NMMainEventsClip

//*********************************************

Function NMPlotWaves(gName, gTitle, xLabel, yLabel, xWave, wList)
	String gName
	String gTitle
	String xLabel
	String yLabel
	String xWave
	String wList
	
	NMDeprecatedAlert("NMGraph")
	
	String folder = ""
	
	STRUCT NMParams nm
	
	NMParamsInit(folder, wList, nm, xWave=xWave)
	
	STRUCT NMGraphStruct g
	NMGraphStructNull(g)
	
	g.gName = gName
	g.gTitle = gTitle
	g.xLabel = xLabel
	g.yLabel = yLabel
	g.xoffset = 0
	g.xoffsetInc = 0
	g.yoffset = 0
	g.yoffsetInc = 0
	g.plotErrors = 0
	g.color = "black"
	
	gName = NMGraph2(nm, g)
	
	if ((strlen(gName) > 0) && (WinType(gName) == 1))
		return 0
	else
		return -1
	endif

End // NMPlotWaves

//*********************************************

Function NMPlotWavesOffset(gName, gTitle, xLabel, yLabel, xWave, wList, xoffset, xoffsetInc, yoffset, yoffsetInc)
	String gName
	String gTitle
	String xLabel
	String yLabel
	String xWave
	String wList
	Variable xoffset, xoffsetInc
	Variable yoffset, yoffsetInc
	
	NMDeprecatedAlert("NMGraph")
	
	String folder = ""
	
	STRUCT NMParams nm
	
	NMParamsInit(folder, wList, nm, xWave=xWave)
	
	STRUCT NMGraphStruct g
	NMGraphStructNull(g)
	
	g.gName = gName
	g.gTitle = gTitle
	g.xLabel = xLabel
	g.yLabel = yLabel
	g.xoffset = xoffset
	g.xoffsetInc = xoffsetInc
	g.yoffset = yoffset
	g.yoffsetInc = yoffsetInc
	g.plotErrors = 0
	g.color = "black"
	
	gName = NMGraph2(nm, g)
	
	if ((strlen(gName) > 0) && (WinType(gName) == 1))
		return 0
	else
		return -1
	endif
	
End // NMPlotWavesOffset

//*********************************************

Function /S NMDisplayWaves(gName, gTitle, xLabel, yLabel, xWave, wList, xoffset, xoffsetInc, yoffset, yoffsetInc, plotErrors)
	String gName
	String gTitle
	String xLabel
	String yLabel
	String xWave
	String wList
	Variable xoffset, xoffsetInc
	Variable yoffset, yoffsetInc
	Variable plotErrors
	
	NMDeprecatedAlert("NMGraph")
	
	String folder = ""
	
	STRUCT NMParams nm
	
	NMParamsInit(folder, wList, nm, xWave=xWave)
	
	STRUCT NMGraphStruct g
	NMGraphStructNull(g)
	
	g.gName = gName
	g.gTitle = gTitle
	g.xLabel = xLabel
	g.yLabel = yLabel
	g.xoffset = xoffset
	g.xoffsetInc = xoffsetInc
	g.yoffset = yoffset
	g.yoffsetInc = yoffsetInc
	g.plotErrors = plotErrors
	g.color = "black"
	
	return NMGraph2(nm, g)
	
End // NMDisplayWaves

//*********************************************

Function NMPlotAppend(gName, color, xWave, wList, xoffset, xoffsetInc, yoffset, yoffsetInc)
	String gName
	String color
	String xWave
	String wList
	Variable xoffset, xoffsetInc
	Variable yoffset, yoffsetInc
	
	NMDeprecatedAlert("NMGraph")
	
	String folder = ""
	
	STRUCT NMParams nm
	
	NMParamsInit(folder, wList, nm, xWave=xWave)
	
	STRUCT NMGraphStruct g
	NMGraphStructNull(g)
	
	g.gName = gName
	g.gTitle = ""
	g.xLabel = ""
	g.yLabel = ""
	g.xoffset = xoffset
	g.xoffsetInc = xoffsetInc
	g.yoffset = yoffset
	g.yoffsetInc = yoffsetInc
	g.plotErrors = 0
	g.color = color
	
	gName = NMGraph2(nm, g)
	
	if ((strlen(gName) > 0) && (WinType(gName) == 1))
		return 0
	else
		return -1
	endif
	
End // NMPlotAppend

//*********************************************

Function /S NMDisplayAppend(gName, color, xWave, wList, xoffset, xoffsetInc, yoffset, yoffsetInc, plotErrors)
	String gName
	String color
	String xWave
	String wList
	Variable xoffset, xoffsetInc
	Variable yoffset, yoffsetInc
	Variable plotErrors
	
	NMDeprecatedAlert("NMGraph")
	
	String folder = ""
	
	STRUCT NMParams nm
	
	NMParamsInit(folder, wList, nm, xWave=xWave)
	
	STRUCT NMGraphStruct g
	NMGraphStructNull(g)
	
	g.gName = gName
	g.gTitle = ""
	g.xLabel = ""
	g.yLabel = ""
	g.xoffset = xoffset
	g.xoffsetInc = xoffsetInc
	g.yoffset = yoffset
	g.yoffsetInc = yoffsetInc
	g.plotErrors = plotErrors
	g.color = color
	
	return NMGraph2(nm, g)

End // NMDisplayAppend

//*********************************************

Function /S NMPlotCall(color)
	String color
	
	return NMMainCall("Graph", color, deprecation=1)
	
End // NMPlotCall

//*********************************************

Function /S NMPlot(color)
	String color

	return NMMainGraph(color=color, deprecation=1)
	
End // NMPlot

//*********************************************

Function /S NMPlotOffset(color, xoffset, yoffset)
	String color
	Variable xoffset, yoffset
	
	return NMMainGraph(color=color, xoffset=xoffset, yoffset=yoffset, deprecation=1)
	
End // NMPlotOffset

//*********************************************

Function /S NMPlotGroups(color, onePlot, reverseGroupOrder, xOffset, yOffset)
	String color
	Variable onePlot
	Variable reverseGroupOrder
	Variable xOffset, yOffset
	
	if (onePlot)
		return NMMainGraph(waveSelectList="All Groups", color=color, reverseOrder=reverseGroupOrder, xoffset=xoffset, yoffset=yoffset, all="All Groups", deprecation=1)
	else
		return NMMainGraph(waveSelectList="All Groups", color=color, reverseOrder=reverseGroupOrder, xoffset=xoffset, yoffset=yoffset, deprecation=1)
	endif
	
End // NMPlotGroups

//*********************************************

Function /S NMMainPlotWaves(color, one, reverseOrder, xoffset, yoffset [ errors ] )
	String color
	Variable one // NOT USED
	Variable reverseOrder
	Variable xoffset
	Variable yoffset
	Variable errors
	
	return NMMainGraph(color=color, reverseOrder=reverseOrder, xoffset=xoffset, yoffset=yoffset, errors=errors, deprecation=1)

End // NMMainPlotWaves

//*********************************************

Function /S NMEditWavesCall()
	
	return NMMainTable(history=1, deprecation=1)

End // NMEditWavesCall

//*********************************************

Function /S NMEditWaves()

	return NMMainTable(deprecation=1)

End // NMEditWaves

//*********************************************

Function EditWaves(tName, tTitle, wList)
	String tName, tTitle
	String wList
	
	tName=NMTable(wList=wList, tName=tName, tTitle=tTitle, deprecation=1)
	
	if (strlen(tName) > 0)
		return 0
	else
		return -1
	endif
	
End // EditWaves

//*********************************************

Function /S NMEditGroups()
	
	return NMMainTable(waveSelectList="All Groups", deprecation=1)

End // NMEditGroups

//*********************************************

Function /S NMXLabelCall()

	return NMMainCall("XLabel", "", deprecation=1)
	
End // NMXLabelCall

//*********************************************

Function /S NMYLabelCall()

	return NMMainCall("YLabel", "", deprecation=1)

End // NMYLabelCall

//*********************************************

Function /S NMLabel(xy, labelStr)
	String xy
	String labelStr
	
	if (StringMatch(xy, "x"))
		NMMainLabel(xLabel=labelStr, deprecation=1)
	elseif (StringMatch(xy, "y"))
		NMMainLabel(yLabel=labelStr, deprecation=1)
	endif
	
End // NMLabel

//*********************************************

Function /S NMInterpolateGroups(algorithm, xmode, xWaveNew)
	Variable algorithm
	Variable xmode
	String xWaveNew
	
	if (xmode == 1)
		return NMMainInterpolate(waveSelectList="All Groups", algorithm=algorithm, xmode=1, deprecation=1)
	else
		return NMMainInterpolate(waveSelectList="All Groups", algorithm=algorithm, xmode=xmode, xWaveNew=xWaveNew, deprecation=1)
	endif

End // NMInterpolateGroups

//*********************************************

Function /S NM2DWaveCall()

	return NMMainCall("2D Wave", "", deprecation=1)

End // NM2DWaveCall

//*********************************************

Function /S NM2DWave(newPrefix)
	String newPrefix
	
	return NMMainConcatenate(newPrefix=newPrefix, dimension=2, deprecation=1)

End // NM2DWave

//*********************************************

Function /S NMConcatWavesCall()

	return NMMainCall("Concatenate", "", deprecation=1)

End // NMConcatWavesCall

//*********************************************

Function /S NMConcatWaves(newPrefix)
	String newPrefix
	
	return NMMainConcatenate(newPrefix=newPrefix, deprecation=1)
	
End // NMConcatWaves

//*********************************************

Function /S NMSplitWaves(newPrefix, outputWaveLength)
	String newPrefix
	Variable outputWaveLength
	
	return NMMainSplit(outputWaveLength=outputWaveLength, newPrefix=newPrefix, deprecation=1)
	
End // NMSplitWaves

//*********************************************

Function /S NMSplitWavesCall()

	return NMMainCall("Split", "", deprecation=1)

End // NMSplitWavesCall

//*********************************************

Function /S NMSplitWaves2(newPrefix, outputWaveLength, xbgn, xend)
	String newPrefix
	Variable outputWaveLength
	Variable xbgn, xend
	
	return NMMainSplit(xbgn=xbgn, xend=xend, outputWaveLength=outputWaveLength, newPrefix=newPrefix, deprecation=1)
	
End // NMSplitWaves2

//*********************************************

Function /S NMDeleteWavesCall()

	return NMMainCall("Kill", "", deprecation=1)

End // NMDeleteWavesCall

//*********************************************

Function /S NMDeleteWaves()
	Variable updateSets
	
	return NMMainKillWaves(deprecation=1)
	
End // NMDeleteWaves

//*********************************************

Function /S NMRenameWaves(find, replacement, search)
	String find, replacement
	String search // NOT USED
	
	return NMMainRename(find=find, replacement=replacement, deprecation=1)
	
End // NMRenameWaves

//*********************************************

Function /S NMRenumWavesCall()

	return NMMainCall("Renumber", "", deprecation=1)

End // NMRenumWavesCall

//*********************************************

Function /S NMRenumWaves(fromNum, alert)
	Variable fromNum
	Variable alert // NOT USED
	
	return NMMainRenumber(fromNum=fromNum, updateSets=1, deprecation=1)
	
End // NMRenumWaves

//*********************************************

Function /S NMHistogramCall()

	return NMMainCall("Histogram", "", deprecation=1)

End // NMHistogramCall

//*********************************************

Function /S NMHistogram(binStart, binWidth, numBins, newPrefix, optionStr)
	Variable binStart
	Variable binWidth
	Variable numBins
	String newPrefix
	String optionStr
	
	return NMMainHistogram(binStart=binStart, binWidth=binWidth, numBins=numBins, optionStr=optionStr, newPrefix=newPrefix, deprecation=1)
	
End // NMHistogram

//*********************************************

Function CheckNMSpikeSubfolder(subfolder)
	String subfolder
	
	NMDeprecatedAlert("CheckNMSubfolder")
	
	return CheckNMSubfolder(subfolder)
	
End // CheckNMSpikeSubfolder

//*********************************************

Function /S NMSpikeSubfolderClear(subfolder)
	String subfolder
	
	NMDeprecatedAlert("NMSubfolderClear")
	
	return NMSubfolderClear(subfolder)

End // NMSpikeSubfolderClear

//*********************************************

Function NMSpikeSubfolderKill(subfolder)
	String subfolder
	
	NMDeprecatedAlert("NMSubfolderKill")
	
	return NMSubfolderKill(subfolder)

End // NMSpikeSubfolderKill

//*********************************************

Function NMSpikeReviewCall(review)
	Variable review
	
	NMDeprecatedAlert("NMSpikeSet")
	
	return NMSpikeSet(review=review, history=1)
	
End // NMSpikeReviewCall

//*********************************************

Function NMSpikeThresholdCall(threshold)
	Variable threshold
	
	NMDeprecatedAlert("NMSpikeSet")
	
	return NMSpikeSet(threshold=threshold, history=1)
	
End // NMSpikeThresholdCall

//*********************************************

Function SpikeThreshold(threshold)
	Variable threshold
	
	NMDeprecatedAlert("NMSpikeSet")
	
	return NMSpikeSet(threshold=threshold)
	
End // SpikeThreshold

//*********************************************

Function NMSpikeThreshold(threshold)
	Variable threshold
	
	NMDeprecatedAlert("NMSpikeSet")
	
	return NMSpikeSet(threshold=threshold)
	
End // NMSpikeThreshold

//*********************************************

Function SpikeWindowCall(xbgn, xend)
	Variable xbgn, xend
	
	NMDeprecatedAlert("NMSpikeSet")
	
	if (numtype(xbgn) != 2)
		NMSpikeSet(xbgn=xbgn, history=1)
	endif
	
	if (numtype(xend) != 2)
		NMSpikeSet(xend=xend, history=1)
	endif
	
End // SpikeWindowCall

//*********************************************

Function SpikeWindow(xbgn, xend)
	Variable xbgn, xend
	
	NMDeprecatedAlert("NMSpikeSet")
	
	return NMSpikeSet(xbgn=xbgn, xend=xend)

End // SpikeWindow

//*********************************************

Function NMSpikeReview(on)
	Variable on
	
	NMDeprecatedAlert("NMSpikeSet")
	
	NMSpikeSet(review=on)

End // NMSpikeReview

//*********************************************

Function SpikeRasterCheckWaves()
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL
	
End // SpikeRasterCheckWaves

//*********************************************

Function SpikeDisplay(chanNum, appnd)
	Variable chanNum
	Variable appnd
	
	NMDeprecatedAlert("NMSpikeDisplay")
	
	return NMSpikeDisplay(chanNum, appnd)
	
End // SpikeDisplay

//*********************************************

Function SpikeDragCall(on)
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(drag=on, history=1)
	
End // SpikeDragCall

//*********************************************

Function SpikeDrag(on)
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(drag=on)
	
End // SpikeDrag

//*********************************************

Function SpikeDragToggle()

	NMDeprecatedAlert("NMChannelGraphSet")

	Variable on = BinaryInvert(NMVarGet("DragOn"))
	
	return NMChannelGraphSet(drag=on)
	
End // SpikeDragToggle

//*********************************************

Function SpikeDragCheck()

	String gName = ChanGraphName(-1)
	String fxnName = ""
	
	NMDeprecatedAlert("NMDragFoldersCheck")

	return NMDragFoldersCheck(gName, fxnName)

End // SpikeDragCheck

//*********************************************

Function SpikeDragTrigger(offsetStr)
	String offsetStr
	
	//NMDeprecatedAlert("SpikeDragTrigger", "NMDragTrigger")
	
	return NMDragTrigger(offsetStr)
	
End // SpikeDragTrigger

//*********************************************

Function SpikeDragSetY()

	NMDeprecatedAlert("NMDragUpdate")
	
	NMDragUpdate("DragBgn")
	NMDragUpdate("DragEnd")

End // SpikeDragSetY

//*********************************************

Function /S SpikeAllGroups(displayMode, delay, format)
	Variable displayMode
	Variable delay
	Variable format // NOT USED
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect("All Groups")
	
	NMDeprecatedAlert("NMSpikeRasterComputeAll")
	
	String folderList = NMSpikeRasterComputeAll(displayMode=displayMode, delay=delay)
	
	NMWaveSelect(saveWaveSelect)
	
	return folderList
	
End // SpikeAllGroups

//*********************************************

Function /S SpikeAllGroupsDelay(displayMode, delay)
	Variable displayMode
	Variable delay
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect("All Groups")
	
	NMDeprecatedAlert("NMSpikeRasterComputeAll")

	String folderList = NMSpikeRasterComputeAll(displayMode=displayMode, delay=delay)
	
	NMWaveSelect(saveWaveSelect)
	
	return folderList

End // SpikeAllGroupsDelay

//*********************************************

Function /S SpikeAllGroupsDelayFormat(displayMode, delay, format)
	Variable displayMode
	Variable delay
	Variable format // NOT USED
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect("All Groups")
	
	NMDeprecatedAlert("NMSpikeRasterComputeAll")

	String folderList = NMSpikeRasterComputeAll(displayMode=displayMode, delay=delay)
	
	NMWaveSelect(saveWaveSelect)
	
	return folderList

End // SpikeAllGroupsDelayFormat

//*********************************************

Function /S SpikeAllWavesDelay(displayMode, delay) 
	Variable displayMode
	Variable delay
	
	NMDeprecatedAlert("NMSpikeRasterComputeAll")
	
	return NMSpikeRasterComputeAll(displayMode=displayMode, delay=delay)
	
End // SpikeAllWavesDelay

//*********************************************

Function /S SpikeAllWavesDelayFormat(displayMode, delay, format) 
	Variable displayMode
	Variable delay
	Variable format // NOT USED
	
	NMDeprecatedAlert("NMSpikeRasterComputeAll")
	
	return NMSpikeRasterComputeAll(displayMode=displayMode, delay=delay)
	
End // SpikeAllWavesDelayFormat

//*********************************************

Function /S SpikeAllWavesCall()

	NMDeprecatedAlert("NMSpikeRasterComputeAllCall")

	return NMSpikeRasterComputeAllCall()

End // SpikeAllWavesCall

//*********************************************

Function /S SpikeAllWaves(displayMode, delay, format)
	Variable displayMode
	Variable delay
	Variable format // NOT USED
	
	NMDeprecatedAlert("NMSpikeRasterComputeAll")
	
	return NMSpikeRasterComputeAll(displayMode=displayMode, delay=delay)
	
End // SpikeAllWaves

//*********************************************

Function /S NMSpikeComputeAllCall()

	NMDeprecatedAlert("NMSpikeRasterComputeAllCall")

	return NMSpikeRasterComputeAllCall()

End // NMSpikeComputeAllCall

//*********************************************

Function /S NMSpikeComputeAll(displayMode, delay, format, plot, table)
	Variable displayMode
	Variable delay
	Variable format // NOT USED
	Variable plot
	Variable table
	
	NMDeprecatedAlert("NMSpikeRasterComputeAll")
	
	return NMSpikeRasterComputeAll(displayMode=displayMode, delay=delay, plot=plot, table=table)
	
End // NMSpikeComputeAll

//*********************************************

Function SpikeRaster(chanNum, waveNum, threshold, xbgn, xend, xRaster, yRaster, displayMode, delay)
	Variable chanNum
	Variable waveNum
	Variable threshold
	Variable xbgn, xend
	String xRaster
	String yRaster
	Variable displayMode
	Variable delay
	
	NMDeprecatedAlert("NMSpikeRasterCompute")
	
	return NMSpikeRasterCompute(chanNum=chanNum, waveNum=waveNum, threshold=threshold, xbgn=xbgn, xend=xend, xRaster=xRaster, yRaster=yRaster, displayMode=displayMode, delay=delay)
	
End // SpikeRaster

//*********************************************

Function /S SpikeRasterSelectWaves()

	NMDeprecatedFatalError("")
	
	return "" // NOT FUNCTIONAL

End // SpikeRasterSelectWaves

//*********************************************

Function SpikeRasterSelect(xWaveOrFolder, yRaster)
	String xWaveOrFolder
	String yRaster // NOT USED
	
	NMDeprecatedAlert("NMSpikeSet")
	
	return NMSpikeSet(raster=xWaveOrFolder)
	
End // SpikeRasterSelect

//*********************************************

Function NMSpikeRasterXSelectCall(xWaveOrFolder)
	String xWaveOrFolder
	
	NMDeprecatedAlert("NMSpikeSet")
	
	return NMSpikeSet(raster=xWaveOrFolder, history=1)
	
End // NMSpikeRasterXSelectCall

//*********************************************

Function NMSpikeRasterXSelect(xWaveOrFolder)
	String xWaveOrFolder
	
	NMDeprecatedAlert("NMSpikeSet")
	
	return NMSpikeSet(raster=xWaveOrFolder)

End // NMSpikeRasterXSelect

//*********************************************

Function /S SpikeRasterPlot(xRasterList, yRasterList, xbgn, xend)
	String xRasterList
	String yRasterList
	Variable xbgn, xend
	
	NMDeprecatedAlert("NMSpikeRasterPlot")
	
	return NMSpikeRasterPlot(xbgn=xbgn, xend=xend)
	
End // SpikeRasterPlot

//*********************************************

Function /S SpikePSTH(xRaster, yRaster, xbgn, xend, binSize, yUnits)
	String xRaster
	String yRaster
	Variable xbgn, xend
	Variable binSize
	String yUnits
	
	NMDeprecatedAlert("NMSpikePSTH")
	
	return NMSpikePSTH(xRasterList=xRaster, yRasterList=yRaster, xbgn=xbgn, xend=xend, binSize=binSize, yUnits=yUnits)
	
End // SpikePSTH

//*********************************************

Function /S SpikeISIH(xRaster, yRaster, xbgn, xend, minInterval, maxInterval, binSize, yUnits)
	String xRaster
	String yRaster // NOT USED
	Variable xbgn, xend
	Variable minInterval
	Variable maxInterval
	Variable binSize
	String yUnits
	
	NMDeprecatedAlert("NMSpikeISIH")
	
	return NMSpikeISIH(xRasterList=xRaster, xbgn=xbgn, xend=xend, minInterval=minInterval, maxInterval=maxInterval, binSize=binSize, yUnits=yUnits)
	
End // SpikeISIH

//*********************************************

Function /S SpikeRate(xRaster, yRaster, xbgn, xend)
	String xRaster
	String yRaster
	Variable xbgn, xend
	
	NMDeprecatedAlert("NMSpikeRate")
	
	return NMSpikeRate(xRasterList=xRaster, yRasterList=yRaster, xbgn=xbgn, xend=xend)
	
End // SpikeRate

//*********************************************

Function Hazard(ISIHname)
	String ISIHname
	
	NMDeprecatedAlert("NMSpikeHazard")
	
	String returnStr = NMSpikeHazard(ISIHname)
	
	return 0
	
End // Hazard

//*********************************************

Function /S Spikes2Waves(xRaster, yRaster, xwinBefore, xwinAfter, stopAtNextSpike, chanNum)
	String xRaster
	String yRaster
	Variable xwinBefore, xwinAfter
	Variable stopAtNextSpike
	Variable chanNum
	
	String wavePrefix = NMSpikeStrGet("S2W_WavePrefix")
	
	wavePrefix = NMPrefixUnique(wavePrefix)
	
	NMDeprecatedAlert("NMSpikesToWaves")
	
	return NMSpikesToWaves(xRaster=xRaster, yRaster=yRaster, xwinBefore=xwinBefore, xwinAfter=xwinAfter, stopAtNextSpike=stopAtNextSpike, chanNum=chanNum, wavePrefix=wavePrefix)
	
End // Spikes2Waves

//*********************************************

Function /S NMSpikes2Waves(xRaster, yRaster, xwinBefore, xwinAfter, stopAtNextSpike, chanNum, wavePrefix)
	String xRaster
	String yRaster
	Variable xwinBefore, xwinAfter
	Variable stopAtNextSpike
	Variable chanNum
	String wavePrefix
	
	NMDeprecatedAlert("NMSpikesToWaves")
	
	return NMSpikesToWaves(xRaster=xRaster, yRaster=yRaster, xwinBefore=xwinBefore, xwinAfter=xwinAfter, stopAtNextSpike=stopAtNextSpike, chanNum=chanNum, wavePrefix=wavePrefix)
	
End // NMSpikes2Waves

//*********************************************

Function /S NMxWaveOrFolder()

	NMDeprecatedAlert("CurrentNMSpikeRasterOrFolder")

	return CurrentNMSpikeRasterOrFolder()

End // NMxWaveOrFolder

//*********************************************

Function /S NMxWaveOrFolderSet(xWaveOrFolder)
	String xWaveOrFolder
	
	NMDeprecatedAlert("NMSpikeSet")
	
	NMSpikeSet(raster=xWaveOrFolder)
	
End // NMxWaveOrFolderSet

//*********************************************

Function UpdateSpike()

	NMDeprecatedAlert("NMSpikeUpdate")
	
	return NMSpikeUpdate()

End // UpdateSpike

//*********************************************

Function /S SpikeCall(fxn, select)
	String fxn, select
	
	NMDeprecatedAlert("NMSpikeCall")
	
	return NMSpikeCall(fxn, select)
	
End // SpikeCall

//*********************************************

Function NMFitFunctionSetCall(fxn)
	String fxn
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(fxn=fxn, history=1)

End // NMFitFunctionSetCall

//*********************************************

Function NMFitPolyNumSetCall(fxn, numTerms)
	String fxn
	Variable numTerms
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(fxn=fxn, numTerms=numTerms, history=1)
	
End // NMFitPolyNumSetCall

//*********************************************

Function NMFitOffsetCall(xoffset)
	Variable xoffset
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(xoffset=xoffset, history=1)
	
End // NMFitOffsetCall

//*********************************************

Function NMFitOffset(xoffset)
	Variable xoffset
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(xoffset=xoffset)
	
End // NMFitOffset

//*********************************************

Function NMFitSinPntsPerCycleCall(pnts)
	Variable pnts
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(pntsPerCycle=pnts, history=1)
	
End // NMFitSinPntsPerCycleCall

//*********************************************

Function NMFitSinPntsPerCycle(pnts)
	Variable pnts
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(pntsPerCycle=pnts)
	
End // NMFitSinPntsPerCycle

//*********************************************

Function NMFitTbgnSetCall(xbgn)
	Variable xbgn
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(xbgn=xbgn, history=1)
	
End // NMFitTbgnSetCall

//*********************************************

Function NMFitSetTbgn(xbgn)
	Variable xbgn
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(xbgn=xbgn)
	
End // NMFitSetTbgn

//*********************************************

Function NMFitTbgnSet(xbgn)
	Variable xbgn
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(xbgn=xbgn)
	
End // NMFitTbgnSet

//*********************************************

Function NMFitTendSetCall(xend)
	Variable xend
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(xend=xend, history=1)
	
End // NMFitTendSetCall

//*********************************************

Function NMFitSetTend(xend)
	Variable xend
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(xend=xend)
	
End // NMFitSetTend

//*********************************************

Function NMFitTendSet(xend)
	Variable xend
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(xend=xend)
	
End // NMFitTendSet

//*********************************************

Function NMFitRangeClearCall()

	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(xbgn=-inf, xend=inf, history=1)

End // NMFitRangeClearCall

//*********************************************

Function NMFitRangeClear()

	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(xbgn=-inf, xend=inf)

End // NMFitRangeClear

//*********************************************

Function NMFitCursorsSetCall()

	Variable cursors = BinaryInvert(NMFitVarGet("Cursors"))
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(cursors=cursors, history=1)

End // NMFitCursorsSetCall

//*********************************************

Function /S NMFitCsrInfo(ab, gName)
	String ab
	String gName
	
	NMDeprecatedFatalError("CsrInfo")
	
	return "" // NOT FUNCTIONAL
	
End // NMFitCsrInfo

//*********************************************

Function NMFitWeightSetCall()

	Variable weighting = BinaryInvert(NMFitVarGet("WeightStdv"))
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(weighting=weighting, history=1)

End // NMFitWeightSetCall

//*********************************************

Function NMFitWeightSet(weighting)
	Variable weighting
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(weighting=weighting)

End // NMFitWeightSet

//*********************************************

Function NMFitFullGraphWidthSetCall()

	Variable fitFullWidth = BinaryInvert(NMFitVarGet("FullGraphWidth"))
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(fitFullWidth=fitFullWidth, history=1)

End // NMFitFullGraphWidthSetCall

//*********************************************

Function NMFitFullGraphWidthSet(fitFullWidth)
	Variable fitFullWidth
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(fitFullWidth=fitFullWidth)

End // NMFitFullGraphWidthSet

//*********************************************

Function NMFitWaveNumPntsCall(npnts)
	Variable npnts
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(fitPoints=npnts, history=1)
	
End // NMFitWaveNumPntsCall

//*********************************************

Function NMFitWaveNumPntsSet(npnts)
	Variable npnts
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(fitPoints=npnts)
	
End // NMFitWaveNumPntsSet

//*********************************************

Function NMFitSaveFitsSetCall()

	Variable fitSave = BinaryInvert(NMFitVarGet("SaveFitWaves"))
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(fitSave=fitSave, history=1)

End // NMFitSaveFitsSetCall

//*********************************************

Function NMFitSaveFitsSet(fitSave)
	Variable fitSave
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(fitSave=fitSave)

End // NMFitSaveFitsSet

//*********************************************

Function NMFitResidualsSetCall()

	Variable fitResiduals = BinaryInvert(NMFitVarGet("Residuals"))
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(fitResiduals=fitResiduals, history=1)

End // NMFitResidualsSetCall

//*********************************************

Function NMFitResidualsSet(fitResiduals)
	Variable fitResiduals
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(fitResiduals=fitResiduals)

End // NMFitResidualsSet

//*********************************************

Function NMFitPrintSetCall()

	Variable printResults = BinaryInvert(NMFitVarGet("PrintResults"))
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(printResults=printResults, history=1)

End // NMFitPrintSetCall

//*********************************************

Function NMFitPrintSet(printResults)
	Variable printResults
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(printResults=printResults)

End // NMFitPrintSet

//*********************************************

Function NMFitAutoSetCall()

	Variable autoFit = BinaryInvert(NMFitVarGet("FitAuto"))
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(autoFit=autoFit, history=1)

End // NMFitAutoSetCall

//*********************************************

Function NMFitAutoSet(autoFit)
	Variable autoFit
	
	NMDeprecatedAlert("NMFitSet")

	return NMFitSet(autoFit=autoFit)

End // NMFitAutoSet

//*********************************************

Function NMFitMaxIterationsCall(maxIterations)
	Variable maxIterations
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Fit" , "MaxIterations" , maxIterations)
	
End // NMFitMaxIterationsCall

//*********************************************

Function NMFitMaxIterationsSet(maxIterations)
	Variable maxIterations
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Fit" , "MaxIterations" , maxIterations)
	
End // NMFitMaxIterationsSet

//*********************************************

Function NMFitAllWavesCall()
	
	NMDeprecatedFatalError("")
	
	return NaN // not functional

End // NMFitAllWavesCall

//*********************************************

Function NMFitAllWaves(pause)
	Variable pause
	
	NMDeprecatedAlert("NMFitAll")

	String tableList = NMFitAll(pause=pause)
	
	return 0
	
End // NMFitAllWaves

//*********************************************

Function NMFitWaveCall()

	NMDeprecatedAlert("NMFitWave")

	return NMFitWave(history=1)

End // NMFitWaveCall

//*********************************************

Function /S NMFitClearCurrentCall()

	NMDeprecatedAlert("NMFitClearCurrent")

	return NMFitClearCurrent(history=1)

End // NMFitClearCurrentCall

//*********************************************

Function /S NMFitClearAllCall()

	NMDeprecatedAlert("NMFitClearAll")

	return NMFitClearAll(history=1)

End // NMFitClearAllCall

//*********************************************

Function NMSynExpSignCall()

	Variable synExpSign = NMFitVarGet("SynExpSign")
	
	// toggle
	
	if (synExpSign == 1)
		synExpSign = -1
	else
		synExpSign = 1
	endif

	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(synExpSign=synExpSign, history=1)

End // NMSynExpSignCall

//*********************************************

Function NMSynExpSign(synExpSign)
	Variable synExpSign
	
	NMDeprecatedAlert("NMFitSet")
	
	return NMFitSet(synExpSign=synExpSign)
	
End // NMSynExpSign

//*********************************************

Function NMEventVar(varName)
	String varName
	
	NMDeprecatedAlert("NMEventVarGet")
	
	return NMEventVarGet(varName)
	
End // NMEventVar

//*********************************************

Function /S NMEventStr(strVarName)
	String strVarName
	
	NMDeprecatedAlert("NMEventStrGet")
	
	return NMEventStrGet(strVarName)
	
End // NMEventStr

//*********************************************

Function EventSearchMethod(method)
	Variable method
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(searchMethod=method)
	
End // EventSearchMethod

//*********************************************

Function MatchTemplateOnCall(on)
	Variable on
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(templateMatching=on, history=1)
	
End // MatchTemplateOnCall

//*********************************************

Function NMEventPositiveCall()
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL
	
End // NMEventPositiveCall

//*********************************************

Function NMEventPositive(positiveEvents)
	Variable positiveEvents
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL
	
End // NMEventPositive

//*********************************************

Function EventThreshold(threshOrLevel)
	Variable threshOrLevel
	
	NMDeprecatedAlert("EventThresholdCall")
	
	return EventThresholdCall(threshOrLevel)
	
End // EventThreshold

//*********************************************

Function EventWindow(on, xbgn, xend)
	Variable on, xbgn, xend
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(xbgn=xbgn, xend=xend)

End // EventWindow

//*********************************************

Function EventSearchWindow(on, xbgn, xend)
	Variable on
	Variable xbgn, xend
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(xbgn=xbgn, xend=xend)

End // EventSearchWindow

//*********************************************

Function NMEventBaselineWin(win)
	Variable win
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(baseWin=win)
			
End // NMEventBaselineWin

//*********************************************

Function NMEventSearchDT(dt)
	Variable dt
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(searchDT=dt)
			
End // NMEventSearchDT

//*********************************************

Function NMEventSearchSkip(skipPnts)
	Variable skipPnts
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(searchSkip=skipPnts)
			
End // NMEventSearchSkip

//*********************************************

Function EventBslnCall(on)
	Variable on
	
	NMDeprecatedAlert("NMEventSearchParamsCall")
	
	return NMEventSearchParamsCall()
	
End // EventBslnCall

//*********************************************

Function EventBsln(on, baseWin, searchDT)
	Variable on
	Variable baseWin
	Variable searchDT
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(baseWin=baseWin, searchDT=searchDT)
	
	return 0
	
End // EventBsln

//*********************************************

Function EventOnset(onsetOn, onsetWin, onsetNstdv, onsetLimit)
	Variable onsetOn
	Variable onsetWin
	Variable onsetNstdv
	Variable onsetLimit
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(onsetOn=onsetOn, onsetWin=onsetWin, onsetNstdv=onsetNstdv, onsetLimit=onsetLimit)
			
End // EventOnset

//*********************************************

Function EventPeak(peakOn, peakWin, peakNstdv, peakLimit)
	Variable peakOn
	Variable peakWin
	Variable peakNstdv
	Variable peakLimit
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(peakOn=peakOn, peakWin=peakWin, peakNstdv=peakNstdv, peakLimit=peakLimit)
			
End // EventPeak

//*********************************************

Function EventSearchTimeCall(t)
	Variable t
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(searchTime=t, history=1)
	
End // EventSearchTimeCall

//*********************************************

Function EventDisplayWinCall(displayWin)
	Variable displayWin
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(displayWin=displayWin, history=1)
	
End // EventDisplayWinCall

//*********************************************

Function EventDisplayWin(displayWin)
	Variable displayWin
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(displayWin=displayWin)
	
End // EventDisplayWin

//*********************************************

Function NMEventReview(on)
	Variable on
	
	NMDeprecatedAlert("NMEventSet")
	
	return NMEventSet(review=on)

End // NMEventReview

//*********************************************

Function NMEventFindNextAfterSaving(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	NMConfigVarSet("Event" , "FindNextAfterSaving" , BinaryCheck(on))

End // NMEventFindNextAfterSaving

//*********************************************

Function NMEventSearchWaveAdvance(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	NMConfigVarSet("Event" , "SearchWaveAdvance" , BinaryCheck(on))

End // NMEventSearchWaveAdvance

//*********************************************

Function NMEventReviewWaveAdvance(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	NMConfigVarSet("Event" , "ReviewWaveAdvance" , BinaryCheck(on))

End // NMEventReviewWaveAdvance

//*********************************************

Function EventSearchCall(func)
	String func
	
	NMDeprecatedAlert("NMEventSearch")
	
	return NMEventSearch(func=func)
	
End // EventSearchCall

//*********************************************

Function /S NMEventTableSelectCall(tableSelect)
	String tableSelect
	
	NMDeprecatedAlert("NMEventSet")
	
	NMEventSet(tableSelect=tableSelect, history=1)
	
	return ""

End // NMEventTableSelectCall

//*********************************************

Function /S EventTableNewCall()

	NMDeprecatedAlert("NMEventTableNew")
	
	return NMEventTableNew(history=1)

End // EventTableNewCall

//*********************************************

Function /S EventTableNew()
	
	NMDeprecatedAlert("NMEventTableNew")
	
	return NMEventTableNew()
	
End // EventTableNew

//*********************************************

Function /S EventTableTitle(tableNum)
	Variable tableNum
	
	NMDeprecatedAlert("NMEventTableTitle")
	
	return NMEventTableTitle()
	
End // EventTableTitle

//*********************************************

Function EventTableSelect(tableNum)
	Variable tableNum
	
	NMDeprecatedAlert("NMEventTableSelect")
	
	String tableName = NMEventTableOldName(CurrentNMChannel(), tableNum)
	
	NMEventTableSelect(tableName)
	
	return 0
	
End // EventTableSelect

//*********************************************

Function EventTableClear(tableNum)
	Variable tableNum
	
	NMDeprecatedAlert("NMEventTableClear")
	
	String tableName = NMEventTableOldName(CurrentNMChannel(), tableNum)
	
	//tableName = CurrentNMEventTableName()
	
	return NMEventTableClear(tableName)
	
End // EventTableClear

//*********************************************

Function EventTableKill(tableNum)
	Variable tableNum
	
	NMDeprecatedAlert("NMEventTableKill")
	
	String tableName = NMEventTableOldName(CurrentNMChannel(), tableNum)
	
	//tableName = CurrentNMEventTableName()
	
	return NMEventTableKill(tableName)
	
End // EventTableKill

//*********************************************

Function EventTable(option, tableNum)
	String option
	Variable tableNum
	
	NMDeprecatedAlert("NMEventTableManager")
	
	String tableName = NMEventTableOldName(CurrentNMChannel(), tableNum)
	
	//tableName = CurrentNMEventTableName()
	
	return NMEventTableManager(tableName, option)
	
End // EventTable

//*********************************************

Function /S EventSetName(tableNum)
	Variable tableNum
	
	NMDeprecatedFatalError("")
	
	return "" // NOT FUNCTIONAL
	
End // EventSetName

//*********************************************

Function EventSetValue(waveNum)
	Variable waveNum
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // EventSetValue

//*********************************************

Function EventSet(option, tableNum)
	String option
	Variable tableNum
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL
	
End // EventSet

//*********************************************

Function /S Event2Wave(wNumWave, eventWave, before, after, stopAtNextEvent, chanNum, wavePrefix)
	String wNumWave
	String eventWave
	Variable before, after
	Variable stopAtNextEvent
	Variable chanNum
	String wavePrefix
	
	NMDeprecatedAlert("NMEventsToWaves")
	
	Variable allowTruncatedEvents = 1
	
	return NMEventsToWaves(wNumWave, eventWave, before, after, stopAtNextEvent, allowTruncatedEvents, chanNum, wavePrefix)
	
End // Event2Wave

//*********************************************

Function /S NMEvent2Wave(waveNumWave, eventWave, xwinBefore, xwinAfter, stopAtNextEvent, allowTruncatedEvents, chanNum, wavePrefix)
	String waveNumWave
	String eventWave
	Variable xwinBefore, xwinAfter
	Variable stopAtNextEvent
	Variable allowTruncatedEvents
	Variable chanNum
	String wavePrefix
	
	NMDeprecatedAlert("NMEventsToWaves")
	
	return NMEventsToWaves(waveNumWave, eventWave, xwinBefore, xwinAfter, stopAtNextEvent, allowTruncatedEvents, chanNum, wavePrefix)
	
End // NMEvent2Wave

//*********************************************

Function EventFindThresh(wName, tbgn, tend, bslnPnts, deltaPnts, thresh, posneg)
	String wName
	Variable tbgn, tend
	Variable bslnPnts
	Variable deltaPnts
	Variable thresh
	Variable posneg
	
	NMDeprecatedAlert("NMEventFindNext")
	
	Variable searchMethod = 0
	
	if (posneg == -1)
		searchMethod = 1
	endif
	
	Variable threshOrNstdv = thresh
	
	return NMEventFindNext(wName, tbgn, tend, bslnPnts, deltaPnts, searchMethod, threshOrNstdv)

End // EventFindThresh

//*********************************************

Function EventHisto(waveOfEventTimes, repetitions, binSize, xbgn, xend, yUnits)
	String waveOfEventTimes
	Variable repetitions
	Variable binSize
	Variable xbgn, xend
	String yUnits
	
	NMDeprecatedAlert("NMEventHistogram")
	
	String histoName = NMEventHistogram(waveOfEventTimes=waveOfEventTimes, repetitions=repetitions, binSize=binSize, xbgn=xbgn, xend=xend, yUnits=yUnits)
	
	return 0
	
End // EventHisto

//*********************************************

Function EventHistoIntvl(waveOfEventTimes, binSize, xbgn, xend, minInterval, maxInterval)
	String waveOfEventTimes
	Variable binSize
	Variable xbgn, xend
	Variable minInterval, maxInterval
	
	NMDeprecatedAlert("NMEventIntervalHistogram")
	
	String histoName = NMEventIntervalHistogram(waveOfEventTimes=waveOfEventTimes, binSize=binSize, xbgn=xbgn, xend=xend, minInterval=minInterval, maxInterval=maxInterval)
	
	return 0
	
End // EventHistoIntvl

//*********************************************

Function NMStatsWavesResetCall()

	NMDeprecatedAlert("NMStatsWavesReset")

	return NMStatsWavesReset(history=1)
	
End // NMStatsWavesResetCall

//*********************************************

Function StatsNumWindowsSet(numWindows)
	Variable numWindows
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(numWindows=numWindows)
	
End // StatsNumWindowsSet

//*********************************************

Function StatsWinSelectCall(winSelect)
	Variable winSelect
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(winSelect=winSelect, history=1)
	
End // StatsWinSelectCall

//*********************************************

Function StatsWinSelect(winSelect)
	Variable winSelect
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(winSelect=winSelect)

End // StatsWinSelect

//*********************************************

Function /S NMStatsSubfolderList2(parentFolder, subfolderPrefix, fullPath, restrictToCurrentPrefix)
	String parentFolder
	String subfolderPrefix
	Variable fullPath
	Variable restrictToCurrentPrefix
	
	NMDeprecatedAlert("NMSubfolderList2")
	
	return NMSubfolderList2(parentFolder, subfolderPrefix, fullPath, restrictToCurrentPrefix)
	
End // NMStatsSubfolderList2

//*********************************************

Function CheckNMStatsSubfolder(subfolder)
	String subfolder
	
	NMDeprecatedAlert("CheckNMSubfolder")
	
	return CheckNMSubfolder(subfolder)
	
End // CheckNMStatsSubfolder

//*********************************************

Function /S NMStatsSubfolderTable(subfolder)
	String subfolder
	
	NMDeprecatedAlert("NMSubfolderTable")
	
	return NMSubfolderTable(subfolder, "ST_")
	
End // NMStatsSubfolderTable

//*********************************************

Function CheckStatsWaves()

	NMDeprecatedAlert("CheckNMStatsWaves")
	
	Variable reset = 0

	return CheckNMStatsWaves(reset) 
	
End // CheckStatsWaves

//*********************************************

Function /S StatsWinList(kind)
	Variable kind
	
	NMDeprecatedAlert("NMStatsWinList")
	
	String prefix = "Win"
	
	return NMStatsWinList(kind, prefix)
	
End // StatsWinList

//*********************************************

Function StatsWinCall(xbgn, xend, fxn)
	Variable xbgn, xend
	String fxn
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(xbgn=xbgn, xend=xend, fxn=fxn, history=1)
	
End // StatsWinCall

//*********************************************

Function NMStatsAmpSelectCall(xbgn, xend, fxn)
	Variable xbgn, xend
	String fxn
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(xbgn=xbgn, xend=xend, fxn=fxn, history=1)

End // NMStatsAmpSelectCall

//*********************************************

Function NMStatsAmpSelectOff(win)
	Variable win
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, fxn="Off")
	
End // NMStatsAmpSelectOff

//*********************************************

Function StatsWin(win, xbgn, xend, fxn)
	Variable win
	Variable xbgn, xend
	String fxn
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, xbgn=xbgn, xend=xend, fxn=fxn)

End // StatsWin

//*********************************************

Function NMStatsAmpSelect(win, xbgn, xend, fxn)
	Variable win
	Variable xbgn, xend
	String fxn
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, xbgn=xbgn, xend=xend, fxn=fxn)

End // NMStatsAmpSelect

//*********************************************

Function StatsLevelCall(level)
	Variable level
	
	 String fxn = StatsAmpSelectGet(-1)
	
	NMDeprecatedAlert("NMStatsSet")
	
	strswitch(fxn)
	
		case "Level":
			return NMStatsSet(level=level, history=1)
			
		case "Level+":
			return NMStatsSet(levelPos=level, history=1)
			
		case "Level-":
			return NMStatsSet(levelNeg=level, history=1)
			
		case "DecayTime+":
		case "DecayTime-":
			
		case "RiseTime+":
		case "RiseTime-":
		
	endswitch
	
End // StatsLevelCall

//*********************************************

Function StatsLevel(win, level)
	Variable win
	Variable level
	
	 String fxn = StatsAmpSelectGet(win)
	 
	 NMDeprecatedAlert("NMStatsSet")
	
	strswitch(fxn)
	
		case "Level":
			return NMStatsSet(win=win, level=level)
			
		case "Level+":
			return NMStatsSet(win=win, levelPos=level)
			
		case "Level-":
			return NMStatsSet(win=win, levelNeg=level)
			
		case "DecayTime+":
		case "DecayTime-":
			
			
		case "RiseTime+":
		case "RiseTime-":
		
	endswitch

End // StatsLevel

//*********************************************

Function StatsLevelStr(win, levelStr)
	Variable win
	String levelStr
	
	Variable level = str2num(levelStr)
	
	 String fxn = StatsAmpSelectGet(win)
	 
	 NMDeprecatedAlert("NMStatsSet")
	
	strswitch(fxn)
	
		case "Level":
			return NMStatsSet(win=win, level=level)
			
		case "Level+":
			return NMStatsSet(win=win, levelPos=level)
			
		case "Level-":
			return NMStatsSet(win=win, levelNeg=level)
			
		case "DecayTime+":
		case "DecayTime-":
			
			
		case "RiseTime+":
		case "RiseTime-":
		
	endswitch
	
End // StatsLevelStr

//*********************************************

Function StatsMaxMinWinSetCall(avgwin)
	Variable avgwin
	
	String fxn = StatsAmpSelectGet(-1)
	
	fxn = fxn[ 0, 5 ]
	
	NMDeprecatedAlert("NMStatsSet")

	strswitch(fxn)
			
		case "MaxAvg":
			return NMStatsSet(maxAvgWin=avgwin, history=1)
			
		case "MinAvg":
			return NMStatsSet(minAvgWin=avgwin, history=1)
	
	endswitch
	
	return -1

End // StatsMaxMinWinSetCall

//*********************************************

Function StatsMaxMinWinSet(win, avgWin)
	Variable win
	Variable avgWin
	
	String fxn = StatsAmpSelectGet(win)
	
	fxn = fxn[ 0, 5 ]
	
	NMDeprecatedAlert("NMStatsSet")

	strswitch(fxn)
			
		case "MaxAvg":
			return NMStatsSet(win=win, maxAvgWin=avgwin)
			
		case "MinAvg":
			return NMStatsSet(win=win, minAvgWin=avgwin)
	
	endswitch
	
	return -1
	
End // StatsMaxMinWinSet

//*********************************************

Function StatsSmoothCall(smthN, smthA)
	Variable smthN
	String smthA
	
	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsSmoothCall

//*********************************************

Function StatsSmooth(win, smthN, smthA)
	Variable win
	Variable smthN
	String smthA
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, filterFxn=smthA, filterNum=smthN)

End // StatsSmooth

//*********************************************

Function StatsFilterCall(filterFxn, filterNum)
	String filterFxn
	Variable filterNum
	
	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsFilterCall

//*********************************************

Function StatsFilterOff(win, filterFxn, filterNum)
	Variable win
	String filterFxn
	Variable filterNum
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, filterNum=0)
	
End // StatsFilterOff

//*********************************************

Function StatsFilter(win, filterFxn, filterNum)
	Variable win
	String filterFxn
	Variable filterNum
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, filterFxn=filterFxn, filterNum=filterNum)
	
End // StatsFilter

//*********************************************

Function NMStatsBslnOff(win)
	Variable win
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, bsln=0)
	
End // NMStatsBslnOff

//*********************************************

Function StatsBsln(win, on, xbgn, xend, fxn, subtract)
	Variable win
	Variable on
	Variable xbgn, xend
	String fxn
	Variable subtract
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, bsln=on, fxn=fxn, xbgn=xbgn, xend=xend, bslnSubtract=subtract)

End // StatsBsln

//*********************************************

Function StatsBslnCallStr(bslnStr)
	String bslnStr
	
	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsBslnCallStr

//*********************************************

Function StatsBslnCall(on, xbgn, xend)
	Variable on
	Variable xbgn, xend
	
	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsBslnCall

//*********************************************

Function StatsBslnReflect(win, on, tbgn, tend, fxn, subtract, center)
	Variable win, on, tbgn, tend
	String fxn
	Variable subtract
	Variable center
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // StatsBslnReflect

//*********************************************

Function StatsBslnReflectUpdate(win)
	Variable win
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // StatsBslnReflectUpdate

//*********************************************

Function StatsFuncCall(on)
	Variable on
	
	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsFuncCall

//*********************************************

Function NMStatsTransformCall(on)
	Variable on
	
	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL
	
End // NMStatsTransformCall

//*********************************************

Function StatsFunc(win, ft)
	Variable win
	Variable ft
	
	String transform = NMChanTransformName(ft)
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, transform=transform)
	
End // StatsFunc

//*********************************************

Function StatsFxn(win, ft)
	Variable win, ft
	
	String transform = NMChanTransformName(ft)
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, transform=transform)
	
End // StatsFxn

//*********************************************

Function NMStatsTransform(win, transform)
	Variable win
	String transform
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, transform=transform)
	
End // NMStatsTransform

//*********************************************

Function StatsOffsetCall(on)
	Variable on
	
	NMDeprecatedAlert("StatsOffsetWinCall")
	
	return StatsOffsetWinCall(on)
	
End // StatsOffsetCall

//*********************************************

Function StatsOffset(win, offName)
	Variable win
	String offName
	
	Variable offsetType
	String wName, typeStr
	
	if (strlen(offName) > 0) 
		
		typeStr = offName[ 0,1 ]
		wName = offName[ 2,inf ]
		
		strswitch(typeStr)
			default:
				return -1
			case "/g":
				offsetType = 1
				break
			case "/w":
				offsetType = 2
				break
		endswitch
		
	endif
	
	NMDeprecatedAlert("NMStatsOffset")
	
	String folder = "_subfolder_"
	Variable baseline = NMStatsVarGet("OffsetBsln")
	Variable table = 1
	
	return NMStatsOffset(win=win, folder=folder, wName=wName, offsetType=offsetType, baseline=baseline, table=table)
	
End // StatsOffset

//*********************************************

Function NMStatsOffsetWin(win, folder, wName, offsetType, baseline, table)
	Variable win
	String folder
	String wName
	Variable offsetType
	Variable baseline
	Variable table
	
	NMDeprecatedAlert("NMStatsOffset")
	
	return NMStatsOffset(win=win, folder=folder, wName=wName, offsetType=offsetType, baseline=baseline, table=table)
	
End // NMStatsOffsetWin

//*********************************************

Function NMStatsOffsetWinOff(win)
	Variable win
	
	NMDeprecatedAlert("NMStatsOffset")
	
	return NMStatsOffset(win=win, offsetType=0)
	
End // NMStatsOffsetWinOff

//*********************************************

Function StatsOffsetWave(wname, offsetType)
	String wname
	Variable offsetType
	
	NMDeprecatedAlert("NMStatsOffsetWave")
	
	String folder = "_subfolder_"
	
	String returnStr = NMStatsOffsetWave(folder, wName, offsetType)
	
	return 0
	
End // StatsOffsetWave

//*********************************************

Function StatsRiseTimeOnset()

	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL

End // StatsRiseTimeOnset

//*********************************************

Function StatsRiseTimeCall(on)
	Variable on
	
	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsRiseTimeCall

//*********************************************

Function StatsRiseTime(win, on, pbgn, pend)
	Variable win
	Variable on
	Variable pbgn, pend
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, risePbgn=pbgn, risePend=pend)

End // StatsRiseTime

//*********************************************

Function StatsDecayTimeCall(on)
	Variable on
	
	NMDeprecatedFatalError("NMStatsSet")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsDecayTimeCall

//*********************************************

Function StatsDecayTime(win, on, percent)
	Variable win
	Variable on
	Variable percent
	
	NMDeprecatedAlert("NMStatsSet")
	
	return NMStatsSet(win=win, decayPcnt=percent)

End // StatsDecayTime

//*********************************************

Function StatsTablesOn(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Stats" , "AutoTables" , BinaryCheck(on))
	
End // StatsTablesOn

//*********************************************

Function NMStatsAutoCall()

	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // NMStatsAutoCall

//*********************************************

Function NMStatsAutoTable(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Stats" , "AutoTables" , BinaryCheck(on))
	
End // NMStatsAutoTable

//*********************************************

Function StatsPlotAutoCall()

	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsPlotAutoCall

//*********************************************

Function StatsPlotAuto(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Stats" , "AutoPlots" , BinaryCheck(on))
	
End // StatsPlotAuto

//*********************************************

Function NMStatsAutoPlot(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Stats" , "AutoPlots" , BinaryCheck(on))
	
End // NMStatsAutoPlot

//*********************************************

Function NMStatsAutoStats2(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Stats" , "AutoStats2" , BinaryCheck(on))
	
End // NMStatsAutoStats2

//*********************************************

Function NMStatsSubfolders(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Stats" , "UseSubfolders" , BinaryCheck(on))
	
End // NMStatsSubfolders

//*********************************************

Function StatsLabelsCall(on)
	Variable on
	
	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL
	
End // StatsLabelsCall

//*********************************************

Function StatsLabels(on)
	Variable on
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Stats" , "GraphLabelsOn" , BinaryCheck(on))
	
End // StatsLabels

//*********************************************

Function StatsLabelsToggle()

	Variable on = NMStatsVarGet("GraphLabelsOn")
	
	NMDeprecatedAlert("NMConfigVarSet")
	
	return NMConfigVarSet("Stats" , "GraphLabelsOn" , !on)
	
End // StatsLabelsToggle

//*********************************************

Function StatsDragCall(on)
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(drag=on, history=1)
	
End // StatsDragCall

//*********************************************

Function StatsDrag(on)
	Variable on
	
	NMDeprecatedAlert("NMChannelGraphSet")
	
	return NMChannelGraphSet(drag=on)
	
End // StatsDrag

//*********************************************

Function StatsDragToggle()

	NMDeprecatedAlert("NMChannelGraphSet")

	Variable on = BinaryInvert(NMVarGet("DragOn"))
	
	return NMChannelGraphSet(drag=on)
	
End // StatsDragToggle

//*********************************************

Function StatsDragCheck()

	NMDeprecatedAlert("NMDragFoldersCheck")
	
	String gName = ChanGraphName(-1)
	String fxnName = "StatsDragTrigger"

	return NMDragFoldersCheck(gName, fxnName)

End // StatsDragCheck

//*********************************************

Function StatsDragSetY()

	NMDeprecatedAlert("NMStatsDragUpdate")
	
	return NMStatsDragUpdate()

End // StatsDragSetY

//*********************************************

Function StatsAllGroups(win, show, delay)
	Variable win
	Variable show
	Variable delay
	
	String windowList
	
	NMDeprecatedAlert("NMStatsCompute")
	
	Variable tables = NMStatsVarGet("AutoTables")
	Variable graphs = NMStatsVarGet("AutoPlots")
	Variable stats2 = NMStatsVarGet("AutoStats2")
	
	String saveWaveSelect = NMWaveSelectGet()
	
	NMWaveSelect("All Groups")
	
	if ((numtype(win) > 0) || (win < 0))
		windowList = "all"
	else
		windowList = num2istr(win)
	endif
	
	Variable rvalue = NMStatsCompute(windowList=windowList, show=show, delay=delay, tables=tables, graphs=graphs, stats2=stats2)
	
	NMWaveSelect(saveWaveSelect)
	
	return rvalue

End // StatsAllGroups

//*********************************************

Function StatsAllWavesCall()

	NMDeprecatedFatalError("NMStatsCompute")
	
	return NaN

End // StatsAllWavesCall

//*********************************************

Function StatsAllWaves(win, show, delay)
	Variable win
	Variable show
	Variable delay
	
	String windowList
	
	NMDeprecatedAlert("NMStatsCompute")
	
	Variable tables = NMStatsVarGet("AutoTables")
	Variable graphs = NMStatsVarGet("AutoPlots")
	Variable stats2 = NMStatsVarGet("AutoStats2")
	
	if ((numtype(win) > 0) || (win < 0))
		windowList = "all"
	else
		windowList = num2istr(win)
	endif
	
	return NMStatsCompute(windowList=windowList, show=show, delay=delay, tables=tables, graphs=graphs, stats2=stats2)

End // StatsAllWaves

//*********************************************

Function NMStatsComputeAllCall()

	NMDeprecatedFatalError("NMStatsCompute")
	
	return NaN

End // NMStatsComputeAllCall

//*********************************************

Function NMStatsComputeAll(win, show, delay, tables, graphs, stats2)
	Variable win
	Variable show
	Variable delay
	Variable tables
	Variable graphs
	Variable stats2
	
	NMDeprecatedAlert("NMStatsCompute")
	
	String windowList
	
	if ((numtype(win) > 0) || (win < 0))
		windowList = "all"
	else
		windowList = num2istr(win)
	endif
	
	return NMStatsCompute(windowList=windowList, show=show, delay=delay, tables=tables, graphs=graphs, stats2=stats2)
	
End // NMStatsComputeAll

//*********************************************

Function /S StatsWavesTables(chanNum, forcenew)
	Variable chanNum
	Variable forcenew // NOT USED
	
	NMDeprecatedAlert("NMStatsWavesTable")
	
	String folder = "_subfolder_"
	
	return NMStatsWavesTable(folder, chanNum, "")
	
End // StatsWavesTables

//*********************************************

Function StatsWinSelectUpdate()

	NMDeprecatedFatalError("")
	
	return NaN // NOT FUNCTIONAL

End // StatsWinSelectUpdate

//*********************************************

Function StatsTableCall()

	NMDeprecatedAlert("NMStatsWinTable")
	
	NMStatsWinTable("inputs")
	NMStatsWinTable("outputs")
	
	return 0

End // StatsTableCall

//*********************************************

Function StatsTableParams(select)
	String select
	
	NMDeprecatedAlert("NMStatsWinTable")
	
	String returnStr = NMStatsWinTable(select)
	
	return 0
	
End // StatsTableParams

//*********************************************

Function /S Stats2Call(fxn)
	String fxn
	
	NMDeprecatedAlert("NMStats2Call")
	
	String select = ""
	
	return NMStats2Call(fxn, select)
	
End // Stats2Call

//*********************************************

Function /S Stats2WSelectCall(wname)
	String wname
	
	NMDeprecatedAlert("NMStatsSet")
	
	NMStatsSet(waveSelect=wName, history=1)
	
	return ""
	
End // Stats2WSelectCall

//*********************************************

Function /S Stats2WSelect(wname)
	String wname
	
	NMDeprecatedAlert("NMStatsSet")
	
	NMStatsSet(waveSelect=wName)
	
	return ""
	
End // Stats2WSelect

//*********************************************

Function /S Stats2WSelectList(filter)
	String filter // NOT USED
	
	NMDeprecatedAlert("NMStats2WaveSelectList")
	
	Variable fullPath = 0
	
	return NMStats2WaveSelectList(fullPath)
	
End // Stats2WSelectList

//*********************************************

Function /S NMStats2WaveSelectCall(folder, wName)
	String folder
	String wName
	
	NMDeprecatedAlert("NMStatsSet")
	
	NMStatsSet(folderSelect=folder, waveSelect=wName, history=1)
	
	return ""

End // NMStats2WaveSelectCall

//*********************************************

Function /S NMStats2WaveSelect(folder, wName)
	String folder
	String wName
	
	NMDeprecatedAlert("NMStatsSet")
	
	NMStatsSet(folderSelect=folder, waveSelect=wName)
	
	return ""

End // NMStats2WaveSelect

//*********************************************

Function Stats2FilterSelectCall()

	NMDeprecatedAlert("NMStats2WaveSelectFilterCall")

	String returnStr = NMStats2WaveSelectFilterCall()
	
	return 0

End // Stats2FilterSelectCall

//*********************************************

Function Stats2FilterSelect(filter)
	String filter
	
	NMDeprecatedAlert("NMStats2WaveSelectFilter")
	
	String returnStr = NMStats2WaveSelectFilter(filter)
	
	return 0
	
End // Stats2FilterSelect

//*********************************************

Function Stats2Compute()

	NMDeprecatedAlert("NMStatsWaveStats")

	String returnStr = NMStatsWaveStats(wList="_selected_", outputSelect=3)
	
	return 0

End // Stats2Compute

//*********************************************

Function /S NMStats2WaveStatsTableCall()
	
	NMDeprecatedFatalError("NMStatsWaveStats")
	
	return ""
	
End // NMStats2WaveStatsTableCall

//*********************************************

Function /S Stats2AllCall()

	NMDeprecatedFatalError("NMStatsWaveStats")
	
	return ""

End // Stats2AllCall

//*********************************************

Function /S Stats2All()

	NMDeprecatedAlert("NMStatsWaveStats")

	return NMStatsWaveStats(outputSelect=2)

End // Stats2All

//*********************************************

Function /S Stats2SaveCall()

	NMDeprecatedFatalError("NMStatsWaveStats")

	return "" // NOT FUNCTIONAL

End // Stats2SaveCall

//*********************************************

Function /S Stats2Save()

	NMDeprecatedFatalError("NMStatsWaveStats")

	return "" // NOT FUNCTIONAL

End // Stats2Save

//*********************************************

Function /S Stats2Table(force)
	Variable force // NOT USED
	
	NMDeprecatedAlert("NMStatsWaveStats")
	
	return NMStatsWaveStats(outputSelect=2)

End // Stats2Table

//*********************************************

Function /S NMStats2WaveStatsTable(folder, waveSelect)
	String folder
	Variable waveSelect // NOT USED
	
	NMDeprecatedAlert("NMStatsWaveStats")
	
	return NMStatsWaveStats(folder=folder, outputSelect=2)
	
End // NMStats2WaveStatsTable

//*********************************************

Function /S NMStats2WaveStatsTableMake(folder, force)
	String folder
	Variable force // NOT USED
	
	NMDeprecatedAlert("NMStatsWaveStats")
	
	return NMStatsWaveStats(folder=folder, outputSelect=2)
	
End // NMStats2WaveStatsTableMake

//*********************************************

Function /S NMStats2WaveStatsTableSave(folder, wName)
	String folder
	String wName
	
	NMDeprecatedFatalError("NMStatsWaveStats")

	return "" // NOT FUNCTIONAL
	
End // NMStats2WaveStatsTableSave

//*********************************************

Function /S NMStats2WaveStatsPrintCall()

	NMDeprecatedFatalError("NMStatsWaveStats")
	
	return ""

End // NMStats2WaveStatsPrintCall

//*********************************************

Function /S NMStats2WaveStatsPrint(folder, waveSelect)
	String folder
	Variable waveSelect // NOT USED
	
	NMDeprecatedAlert("NMStatsWaveStats")

	return NMStatsWaveStats(folder=folder, outputSelect=0)
	
End // NMStats2WaveStatsPrint

//*********************************************

Function NMStats2PrintWaveStatsCall()

	NMDeprecatedFatalError("NMStatsWaveStats")

	return NaN // NOT FUNCTIONAL

End // NMStats2PrintWaveStatsCall

//*********************************************

Function NMStats2WaveStats(wName, printToHistory)
	String wName
	Variable printToHistory
	
	String returnStr
	
	NMDeprecatedAlert("NMStatsWaveStats")
	
	if (printToHistory)
		returnStr = NMStatsWaveStats(wList=wName, outputSelect=0)
	else
		returnStr = NMStatsWaveStats(wList=wName, outputSelect=3)
	endif
	
	return 0
	
End // NMStats2WaveStats

//*********************************************

Function /S NMStats2PrintNotesCall()

	NMDeprecatedFatalError("NMStatsWaveNotes")

	return ""
	
End // NMStats2PrintNotesCall

//*********************************************

Function /S NMStats2PrintNotes(folder, toNotebook)
	String folder
	Variable toNotebook
	
	NMDeprecatedAlert("NMStatsWaveNotes")
	
	return NMStatsWaveNotes(folder=folder, toNotebook=toNotebook)
	
End // NMStats2PrintNotes

//*********************************************

Function /S StatsEditCall()

	NMDeprecatedFatalError("NMStatsEdit")

	return "" // NOT FUNCTIONAL

End // StatsEditCall

//*********************************************

Function /S NMStats2EditCall()

	NMDeprecatedFatalError("NMStatsEdit")

	return "" // NOT FUNCTIONAL
	
End // NMStats2EditCall

//*********************************************

Function /S StatsEdit(wName)
	String wName
	
	NMDeprecatedAlert("NMStatsEdit")
	
	return NMStatsEdit(wList=wName)
	
End // StatsEdit

//*********************************************

Function /S NMStats2Edit(wName)
	String wName
	
	NMDeprecatedAlert("NMStatsEdit")
	
	return NMStatsEdit(wList=wName)
	
End // NMStats2Edit

//*********************************************

Function /S StatsWavesEditCall()

	NMDeprecatedAlert("NMStatsEdit")

	return NMStatsEdit(history=1)
	
End // StatsWavesEditCall

//*********************************************

Function /S NMStats2EditAllCall()

	NMDeprecatedAlert("NMStatsEdit")

	return NMStatsEdit(history=1)

End // NMStats2EditAllCall

//*********************************************

Function /S NMStatsEditAllCall()

	NMDeprecatedAlert("NMStatsEdit")

	return NMStatsEdit(history=1)
	
End // NMStatsEditAllCall

//*********************************************

Function /S StatsWavesEdit(select)
	String select // NOT USED
	
	NMDeprecatedAlert("NMStatsEdit")
	
	return NMStatsEdit()

End // StatsWavesEdit

//*********************************************

Function /S NMStats2EditAll(folder, waveSelect)
	String folder
	Variable waveSelect // NOT USED
	
	NMDeprecatedAlert("NMStatsEdit")
	
	return NMStatsEdit(folder=folder)
	
End // NMStats2EditAll

//*********************************************

Function /S StatsPrintNamesCall()

	NMDeprecatedFatalError("NMStatsWaveNames")

	return ""

End // StatsPrintNamesCall

//*********************************************

Function /S StatsPrintNames(select)
	String select // NOT USED
	
	NMDeprecatedAlert("NMStatsWaveNames")
	
	String folder = "_selected_"
	Variable fullPath = 0
	
	return NMStatsWaveNames(folder=folder, fullPath=fullpath)
	
End // StatsPrintNames

//*********************************************

Function /S NMStats2PrintNamesCall()

	NMDeprecatedFatalError("NMStatsWaveNames")

	return ""
	
End // NMStats2PrintNamesCall

//*********************************************

Function /S NMStats2PrintNames(folder, option, fullPath)
	String folder
	Variable option // NOT USED
	Variable fullPath
	
	NMDeprecatedAlert("NMStatsWaveNames")

	return NMStatsWaveNames(folder=folder, fullPath=fullpath)
	
End // NMStats2PrintNames

//*********************************************

Function /S NMStats2PrintName(wName)
	String wName
	
	NMDeprecatedFatalError("NMStatsWaveNames")
	
	return "" // NOT FUNCTIONAL
	
End // NMStats2PrintName

//*********************************************

Function /S NMStats2PrintNoteCall()

	String wName = CurrentNMStats2WaveSelect(0)

	NMDeprecatedAlert("NMStatsWaveNotes")

	return NMStatsWaveNotes(wList=wName, history=1)
	
End // NMStats2PrintNoteCall

//*********************************************

Function /S NMStats2PrintNote(wName)
	String wName
	
	NMDeprecatedAlert("NMStatsWaveNotes")
	
	return NMStatsWaveNotes(wList=wName)
	
End // NMStats2PrintNote

//*********************************************

Function Stats2Display()

	NMDeprecatedFatalError("")

	return NaN // NOT FUNCTIONAL
	
End // Stats2Display

//*********************************************

Function /S NMStats2WaveScaleCall()

	NMDeprecatedFatalError("NMStatsWaveScale")
	
	return "" // NOT FUNCTIONAL
	
End // NMStats2WaveScaleCall

//*********************************************

Function /S NMStats2WaveScale(waveOfWaveNames, waveOfScaleValues, alg, chanSelect)
	String waveOfWaveNames
	String waveOfScaleValues
	String alg
	String chanSelect
	
	NMDeprecatedAlert("NMStatsWaveScale")
	
	return NMStatsWaveScale(waveOfScaleValues=waveOfScaleValues, waveOfWaveNames=waveOfWaveNames, alg=alg, chanSelect=chanSelect)
	
End // NMStats2WaveScale

//*********************************************

Function /S NMStats2WaveAlignmentCall()

	NMDeprecatedFatalError("NMStatsWaveAlignment")
	
	return "" // NOT FUNCTIONAL
	
End // NMStats2WaveAlignmentCall

//*********************************************

Function /S NMStats2WaveAlignment(waveOfWaveNames, waveOfAlignValues, alignAtZero, chanSelect)
	String waveOfWaveNames
	String waveOfAlignValues
	Variable alignAtZero
	String chanSelect
	
	NMDeprecatedAlert("NMStatsWaveAlignment")
	
	Variable alignAt = NMAlignAtValueOld(alignAtZero, waveOfAlignValues)
	
	return NMStatsWaveAlignment(waveOfAlignments=waveOfAlignValues, waveOfWaveNames=waveOfWaveNames, alignAt=alignAt, chanSelect=chanSelect)
	
End // NMStats2WaveAlignment

//*********************************************

Function /S StatsSort(wName, wSelect)
	String wName
	Variable wSelect
	
	NMDeprecatedFatalError("NMStatsRelationalOperator")
	
	return "" // NOT FUNCTIONAL

End // StatsSort

//*********************************************

Function /S StatsSortWave(wName, select, aValue, sValue, nValue)
	String wName
	Variable select
	Variable aValue
	Variable sValue
	Variable nValue
	
	STRUCT NMInequalityStructOld s
	
	NMInequalityStructConvert(select, aValue, sValue, nValue, s)
	
	return NMStatsInequality(wName=wName, greaterThan=s.greaterThan, lessThan=s.lessThan, deprecation=1)
	
End // StatsSortWave

//*********************************************

Function /S NMStats2SortWave(wName, select, aValue, sValue, nValue, setName)
	String wName
	Variable select
	Variable aValue
	Variable sValue
	Variable nValue
	String setName
	
	STRUCT NMInequalityStructOld s
	
	NMInequalityStructConvert(select, aValue, sValue, nValue, s)
	
	return NMStatsInequality(wName=wName, greaterThan=s.greaterThan, lessThan=s.lessThan, setName=setName, deprecation=1)
	
End // NMStats2SortWave

//*********************************************

Function /S NMStatsComparisonOperatorCall()

	NMDeprecatedFatalError("NMStatsRelationalOperator")

	return "" // NOT FUNCTIONAL

End // NMStatsComparisonOperatorCall

//*********************************************

Function /S NMStatsComparisonOperator(wName, select, aValue, sValue, nValue, setName)
	String wName
	Variable select
	Variable aValue
	Variable sValue
	Variable nValue
	String setName
	
	STRUCT NMInequalityStructOld s
	
	NMInequalityStructConvert(select, aValue, sValue, nValue, s)
	
	return NMStatsInequality(wName=wName, greaterThan=s.greaterThan, lessThan=s.lessThan, setName=setName, deprecation=1)
	
End // NMStatsComparisonOperator

//*********************************************

Function /S StatsHisto(wName)
	String wName
	
	NMDeprecatedAlert("NMStatsHistogram")
	
	return NMStatsHistogram(wName=wName)
	
End // StatsHisto

//*********************************************

Function /S NMStats2Histogram(wName, binWidth)
	String wName
	Variable binWidth
	
	NMDeprecatedAlert("MStatsHistogram")
	
	return NMStatsHistogram(wName=wName, binWidth=binWidth)
	
End // NMStats2Histogram

//*********************************************

Function /S Stats2WSelectDefault()

	NMDeprecatedFatalError("")
	
	return "" // NOT FUNCTIONAL

End // Stats2WSelectDefault

//*********************************************

Function /S StatsPlotCall()

	NMDeprecatedFatalError("NMStatsPlot")

	return "" // NOT FUNCTIONAL

End // StatsPlotCall

//*********************************************

Function /S StatsPlot(wName)
	String wName
	
	NMDeprecatedAlert("NMStatsPlot")
	
	return NMStatsPlot(wList=wName)
	
End // StatsPlot

//*********************************************

Function /S NMStats2PlotCall()

	NMDeprecatedFatalError("NMStatsPlot")

	return "" // NOT FUNCTIONAL

End // NMStats2PlotCall

//*********************************************

Function /S NMStats2Plot(waveNameY, waveNameX)
	String waveNameY
	String waveNameX
	
	NMDeprecatedAlert("NMStatsPlot")
	
	return NMStatsPlot(wList=waveNameY, xWave=waveNameX)
	
End // NMStats2Plot

//*********************************************

Function /S StatsDeleteNANsCall()

	NMDeprecatedFatalError("")

	return "" // NOT FUNCTIONAL

End // StatsDeleteNANsCall

//*********************************************

Function /S StatsDeleteNANs(wName)
	String wName

	NMDeprecatedFatalError("")
	
	//SetNMStatsVar("WaveLengthFormat", 1) // USE THIS FLAG INSTEAD
	
	return "" // NOT FUNCTIONAL
	
End // StatsDeleteNANs

//*********************************************

Function /S StatsWavesKillCall()

	NMDeprecatedFatalError("NMStatsSubfolderClear")
	
	return "" // NOT FUNCTIONAL

End // StatsWavesKillCall

//*********************************************

Function /S StatsWavesKill(select)
	String select
	
	NMDeprecatedAlert("NMStatsSubfolderClear")
	
	return NMStatsSubfolderClear(subfolder="_selected_")

End // StatsWavesKill

//*********************************************

Function /S NMStats2FolderClearCall()

	NMDeprecatedFatalError("NMStatsSubfolderClear")
	
	return "" // NOT FUNCTIONAL
	
End // NMStats2FolderClearCall

//*********************************************

Function /S NMStats2FolderClear(subfolder)
	String subfolder
	
	NMDeprecatedAlert("NMStatsSubfolderClear")
	
	return NMStatsSubfolderClear(subfolder=subfolder)
	
End // NMStats2FolderClear

//*********************************************

Function /S NMStats2FolderKillCall()

	NMDeprecatedFatalError("NMStatsSubfolderKill")
	
	return "" // NOT FUNCTIONAL

End // NMStats2FolderKillCall

//*********************************************

Function /S NMStats2FolderKill(subfolder)
	String subfolder
	
	NMDeprecatedAlert("NMStatsSubfolderKill")
	
	return NMStatsSubfolderKill(subfolder=subfolder)

End // NMStats2FolderKill

//*********************************************

Function /S StatsStabilityCall()

	NMDeprecatedAlert("NMStats2StabilityCall")

	return NMStats2StabilityCall()

End // StatsStabilityCall

//*********************************************

Function /S NMStability(wName, bgnPnt, endPnt, minArray, sig, win2Frac)
	String wName
	Variable bgnPnt
	Variable endPnt
	Variable minArray
	Variable sig
	Variable win2Frac
	
	NMDeprecatedAlert("NMStabilityRankOrderTest")
	
	String setName = ""
	
	return NMStabilityRankOrderTest(wName, bgnPnt, endPnt, minArray, sig, win2Frac, setName)
	
End // NMStability

//*********************************************

Function KSTestCall()

	NMDeprecatedAlert("NMKSTestCall")
	
	return NMKSTestCall()

End // KSTestCall

//*********************************************

Function KSTest(wName1, wName2, dsply)
	String wName1, wName2
	Variable dsply
	
	NMDeprecatedAlert("NMKSTest")
	
	return NMKSTest(wName1=wName1, wName2=wName2, noGraph=BinaryInvert(dsply))

End // KSTest

//*********************************************

Function /S NMOrderWavesPref()

	NMDeprecatedAlert("NMStrGet")

	return NMStrGet("OrderWavesBy")

End // NMOrderWavesPref()

//*********************************************

Function NMOrderWavesPrefSet(order)
	String order
	
	NMDeprecatedAlert("NMSet")
	
	return NMSet(OrderWavesBy=order)
	
End // NMOrderWavesPrefSet

//*********************************************

Function /S WaveListOfSize(wavesize, matchStr)
	Variable wavesize
	String matchStr
	
	NMDeprecatedAlert("WaveList")
	
	String optionsStr = NMWaveListOptions(waveSize, 0)
	
	return WaveList(matchStr, ";", optionsStr)

End // WaveListOfSize

//*********************************************

Function /S WaveListFolder(folder, matchStr, separatorStr, optionsStr)
	String folder
	String matchStr, separatorStr, optionsStr
	
	NMDeprecatedAlert("NMFolderWaveList")
	
	return NMFolderWaveList(folder, matchStr, separatorStr, optionsStr, 0)
	
End // WaveListFolder

//*********************************************

Function /S WaveListText0()

	NMDeprecatedAlert("")

	return "Text:0"
	
End // WaveListText0

//*********************************************

Function /S NMCopyWavesCall()

	return NMMainCall("Copy", "", deprecation=1)

End // NMCopyWavesCall

//*********************************************

Function /S NMCopyWaves(newPrefix, xbgn, xend, options)
	String newPrefix
	Variable xbgn, xend
	Variable options
	
	Variable copySets, selectNewPrefix
	 
	if ((options & 2^0) != 0)
		selectNewPrefix = 1 // NOT USED
	endif
	
	if ((options & 2^1) != 0)
		copySets = 1
	endif
	
	return NMMainDuplicate(xbgn=xbgn, xend=xend, newPrefix=newPrefix, copySets=copySets, deprecation=1)
	
End // NMCopyWaves

//*********************************************

Function /S CopyWaves(newPrefix, xbgn, xend, wList)
	String newPrefix
	Variable xbgn, xend
	String wList
	
	return NMDuplicate(wList, xbgn=xbgn, xend=xend, newPrefix=newPrefix, deprecation=1)
	
End // CopyWaves

//*********************************************

Function /S CopyAllWavesTo(fromFolder, toFolder, alert)
	String fromFolder, toFolder
	Variable alert // NOT USED, see overwrite flag
	
	String wList = "_ALL_"
	
	return NMDuplicate(wList, folder=fromFolder, toFolder=toFolder, overwrite=0, deprecation=1)
	
End // CopyAllWavesTo

//*********************************************

Function /S CopyWavesTo(fromFolder, toFolder, newPrefix, xbgn, xend, wList, alert)
	String fromFolder
	String toFolder
	String newPrefix
	Variable xbgn, xend
	String wList
	Variable alert // NOT USED, see overwrite flag
	
	return NMDuplicate(wList, folder=fromFolder, xbgn=xbgn, xend=xend, toFolder=toFolder, newPrefix=newPrefix, overwrite=0, deprecation=1)
	
End // CopyWavesTo

//*********************************************

Function /S NMCopyWavesToCall()
	
	return NMMainCall("Copy", "", deprecation=1)
	
End // NMCopyWavesToCall

//*********************************************

Function /S NMCopyWavesTo(toFolder, newPrefix, xbgn, xend, alert, options)
	String toFolder
	String newPrefix
	Variable xbgn, xend
	Variable alert
	Variable options
	
	Variable copySets, selectNewPrefix
	 
	if ((options & 2^0) != 0)
		selectNewPrefix = 1 // NOT USED
	endif
	
	if ((options & 2^1) != 0)
		copySets = 1
	endif
	
	return NMMainDuplicate(xbgn=xbgn, xend=xend, toFolder=toFolder, newPrefix=newPrefix, copySets=copySets, deprecation=1)
	
End // NMCopyWavesTo

//*********************************************

Function /S RenameWavesx(findStr, repStr, wList)
	String findStr
	String repStr
	String wList
	
	return NMRenameWavesSafely(findStr, repStr, wList, deprecation=1)

End // RenameWaves

//*********************************************

Function /S RenumberWaves(fromNum, wList)
	Variable fromNum
	String wList
	
	return NMRenumberWavesSafely(fromNum=fromNum, wList=wList, deprecation=1)
	
End // RenumberWaves

//*********************************************

Function /S DeleteWaves(wList)
	String wList
	
	return NMKillWaves(wList, deprecation=1)
	
End // DeleteWaves

//*********************************************

Function /S NMScaleByNumCall()

	return NMMainCall("Scale By Num", "", deprecation=1)

End // NMScaleByNumCall

//*********************************************

//Function /S NMScaleByNum(algorithm, num) // name is used in NM_Utility
//	String algorithm
//	Variable num
	
//	algorithm += num2str(num)
//	
//	return NMMainScaleByNum(algorithm=algorithm, deprecation=1)

//End // NMScaleByNum

//*********************************************

Function /S NMScaleWaveCall()

	return NMMainCall("Scale By Num", "", deprecation=1)

End // NMScaleWaveCall

//*********************************************

Function /S NMScaleWave(op, factor, xbgn, xend)
	String op
	Variable factor
	Variable xbgn, xend
	
	return NMMainScale(op=op, factor=factor, xbgn=xbgn, xend=xend, deprecation=1)
	
End // NMScaleWave

//*********************************************

Function /S ScaleByNum(op, factor, wList)
	String op
	Variable factor
	String wList
	
	return NMScale(op, wList, factor=factor, deprecation=1)

End // ScaleByNum

//*********************************************

Function /S ScaleWave(op, factor, xbgn, xend, wList)
	String op
	Variable factor
	Variable xbgn, xend
	String wList
	
	return NMScale(op, wList, factor=factor, xbgn=xbgn, xend=xend, deprecation=1)

End // ScaleWave

//*********************************************

Function /S NMScaleWaves(op, factor, xbgn, xend, wList)
	String op
	Variable factor
	Variable xbgn, xend
	String wList
	
	return NMScale(op, wList, factor=factor, xbgn=xbgn, xend=xend, deprecation=1)
	
End // NMScaleWaves

//*********************************************

Function /S ScaleByWave(op, wavePntByPnt, wList)
	String op
	String wavePntByPnt
	String wList
	
	return NMScale(op, wList, wavePntByPnt=wavePntByPnt, deprecation=1)
	
End // ScaleByWave

//*********************************************

Function /S NMScaleByWaveCall()

	return NMMainCall("Scale By Wave", "", deprecation=1)

End // NMScaleByWaveCall

//*********************************************

Function /S NMScaleByWave(method, op, scaleWaveName)
	Variable method 
	String op
	String scaleWaveName
	
	if (method == 1)
		return NMMainScale(op=op, waveOfFactors=scaleWaveName, deprecation=1)
	elseif (method == 2)
		return NMMainScale(op=op, wavePntByPnt=scaleWaveName, deprecation=1)
	endif
	
End // NMScaleByWave

//*********************************************

Function /S NMYUnitsChangeCall()

	return NMMainCall("Rescale", "", deprecation=1)

End // NMYUnitsChangeCall

//*********************************************

Function /S NMYUnitsChange(channel, oldUnits, newUnits, scale)
	Variable channel
	String oldUnits, newUnits
	Variable scale
	
	String chanSelect = ChanNum2Char(ChanNumCheck(channel))
	
	return NMMainRescale(chanSelectList=chanSelect, oldUnits=oldUnits, newUnits=newUnits, scale=scale, deprecation=1)
	
End // NMYUnitsChange

//*********************************************

Function /S ReverseWaves(wList)
	String wList

	return NMReverse(wList, deprecation=1)
	
End // ReverseWaves

//*********************************************
//*********************************************

Function /S SortWavesByKeyWave(sortKeyWave, wList)
	String sortKeyWave
	String wList
	
	return NMSort(sortKeyWave, wList, deprecation=1)
	
End // SortWavesByKeyWave

//*********************************************

Function /S BreakWave(wName, outPrefix, npnts)
	String wName
	String outPrefix
	Variable npnts
	
	if (WaveExists($wName) == 0)
		return ""
	endif
	
	Variable chanNum = -1
	Variable xbgn = -inf
	Variable xend = inf
	Variable splitWaveLength = npnts * deltax($wName)

	return NMSplitWave(wName, outPrefix, chanNum, xbgn, xend, splitWaveLength, deprecation=1)

End // BreakWave

//*********************************************

//Function /S SplitWave(wName, outPrefix, chanNum, npnts) // name conflict with Igor function
	//String wName
	//String outPrefix
	//Variable chanNum
	//Variable npnts
	
	//Variable xbgn = -inf
	//Variable xend = inf
	//Variable splitWaveLength = npnts * deltax($wName)
	
	//return NMSplitWave(wName, outPrefix, chanNum, xbgn, xend, splitWaveLength, deprecation=1)
	
//End // SplitWave

//*********************************************

Function /S NMEventsClip(positiveEvents, eventFindLevel, xwinBeforeEvent, xwinAfterEvent, wList [ waveOfEventTimes, clipValue ])
	Variable positiveEvents
	Variable eventFindLevel
	Variable xwinBeforeEvent
	Variable xwinAfterEvent
	String wList
	String waveOfEventTimes
	Variable clipValue
	
	if (ParamIsDefault(waveOfEventTimes))
		if (ParamIsDefault(clipValue))
			return NMClipEvents(xwinBeforeEvent, xwinAfterEvent, wList, eventFindLevel=eventFindLevel, positiveEvents=positiveEvents, deprecation=1)
		else
			return NMClipEvents(xwinBeforeEvent, xwinAfterEvent, wList, eventFindLevel=eventFindLevel, positiveEvents=positiveEvents, clipValue=clipValue, deprecation=1)
		endif
	else
		if (ParamIsDefault(clipValue))
			return NMClipEvents(xwinBeforeEvent, xwinAfterEvent, wList, waveOfEventTimes=waveOfEventTimes, deprecation=1)
		else
			return NMClipEvents(xwinBeforeEvent, xwinAfterEvent, wList, waveOfEventTimes=waveOfEventTimes, clipValue=clipValue, deprecation=1)
		endif
	endif
	
End // NMEventsClip

//*********************************************

Function /S BlankWaves(waveOfEventTimes, xwinBeforeEvent, xwinAfterEvent, blankValue, wList)
	String waveOfEventTimes
	Variable xwinBeforeEvent
	Variable xwinAfterEvent
	Variable blankValue
	String wList
	
	return NMClipEvents(xwinBeforeEvent, xwinAfterEvent, wList, waveOfEventTimes=waveOfEventTimes, clipValue=blankValue, deprecation=1)
	
End // BlankWaves

//*********************************************

Function /S NormWaves(fxn2, xbgn2, xend2, xbgn1, xend1, wList)
	String fxn2
	Variable xbgn2, xend2
	Variable xbgn1, xend1
	String wList
	
	Variable avgWin2
	
	STRUCT NMNormalizeStruct n
	
	n.fxn1 = "avg"
	n.xbgn1 = xbgn1
	n.xend1 = xend1
	n.minValue = 0
	
	if (StringMatch(fxn2[ 0, 5 ], "MaxAvg"))
		fxn2 = "MaxAvg"
		avgWin2 = str2num(fxn2[ 6, inf ])
	endif 
	
	n.fxn2 = fxn2
	n.avgWin2 = avgWin2
	n.xbgn2 = xbgn2
	n.xend2 = xend2
	n.maxValue = 1
	
	return NMNormalize(wList, n=n, deprecation=1)

End // NormWaves

//*********************************************

Function /S NormalizeWaves(fxn1, xbgn1, xend1, fxn2, xbgn2, xend2, wList)
	String fxn1
	Variable xbgn1, xend1
	String fxn2
	Variable xbgn2, xend2
	String wList
	
	Variable avgWin1, avgWin2
	
	STRUCT NMNormalizeStruct n
	
	if (StringMatch(fxn1[ 0, 5 ], "MinAvg"))
		fxn1 = "MinAvg"
		avgWin1 = str2num(fxn1[ 6, inf ])
	endif 
	
	n.fxn1 = fxn1
	n.avgWin1 = avgWin1
	n.xbgn1 = xbgn1
	n.xend1 = xend1
	n.minValue = 0
	
	if (StringMatch(fxn2[ 0, 5 ], "MaxAvg"))
		fxn2 = "MaxAvg"
		avgWin2 = str2num(fxn2[ 6, inf ])
	endif 
	
	n.fxn2 = fxn2
	n.avgWin2 = avgWin2
	n.xbgn2 = xbgn2
	n.xend2 = xend2
	n.maxValue = 1
	
	return NMNormalize(wList, n=n, deprecation=1)
	
End // NormalizeWaves

//*********************************************

Function /S AvgWaves(wList)
	String wList
	
	return NMMatrixStats(wList, truncateToCommonXScale=1, deprecation=1)

End // AvgWaves

//*********************************************

Function /S AvgWavesPntByPnt(wList)
	String wList
	
	return NMMatrixStats(wList, truncateToCommonXScale=0, deprecation=1)

End // AvgWavesPntByPnt

//*********************************************

Function /S AvgChanWaves(chanNum, wList)
	Variable chanNum
	String wList
	
	return NMMatrixStats(wList, chanTransforms=chanNum, truncateToCommonXScale=1, deprecation=1)

End // AvgChanWaves

//*********************************************

Function /S SumWaves(wList)
	String wList

	return NMMatrixStats(wList, truncateToCommonXScale=1, deprecation=1)

End // SumWaves

//*********************************************

Function /S SumChanWaves(chanNum, wList)
	Variable chanNum
	String wList
	
	return NMMatrixStats(wList, chanTransforms=chanNum, truncateToCommonXScale=1, deprecation=1)

End // SumChanWaves

//*********************************************

Function /S Make2DWave(wList)
	String wList
	
	return NMMatrixStats(wList, saveMatrix=1, deprecation=1)

End // Make2DWave

//*********************************************

Function /S NMWavesStatistics(wList, chanTransforms, ignoreNANs, truncateToCommonXScale, interpToSameDX, saveMatrix)
	String wList
	Variable chanTransforms
	Variable ignoreNANs
	Variable truncateToCommonXScale
	Variable interpToSameDX // NOT USED, does automatically
	Variable saveMatrix
	
	return NMMatrixStats(wList, chanTransforms=chanTransforms, ignoreNANs=ignoreNANs, truncateToCommonXScale=truncateToCommonXScale, saveMatrix=saveMatrix, deprecation=1)
	
End // NMWavesStatistics

//*********************************************

Function CopyWaveValues(fromFolder, toFolder, wList, fromOffset, toOffset)
	String fromFolder
	String toFolder
	String wList // wave list (seperator ";")
	Variable fromOffset
	Variable toOffset
	
	NMDeprecatedFatalError("CopyWavesTo")
	
	return NaN

End // CopyWaveValues

//*********************************************

Function /S FindSlope(xbgn, xend, wName)
	Variable xbgn, xend 
	String wName
	
	return NMLinearRegression(wName, xbgn=xbgn, xend=xend, deprecation=1)
	
End // FindSlope

//*********************************************

Function /S FindMaxCurvatures(xbgn, xend, wName)
	Variable xbgn, xend // x-axis window begin and end, use (-inf, inf) for all
	String wName // wave name
	
	return NMMaxCurvatures(wName, xbgn=xbgn, xend=xend, deprecation=1)
	
End // FindMaxCurvatures

//*********************************************

Function FindLevelPosNeg(tbgn, tend, level, direction, wName)
	Variable tbgn
	Variable tend
	Variable level
	String direction
	String wName
	
	NMDeprecatedAlert("FindLevel /EDGE")
	
	strswitch(direction)
	
		case "+":
			FindLevel /EDGE=1/Q/R=(tbgn, tend) $wname, level
			break
			
		case "-":
			FindLevel /EDGE=2/Q/R=(tbgn, tend) $wname, level
			break
			
		default:
			return Nan
			
	endswitch
	
	return V_LevelX

End // FindLevelPosNeg

//*********************************************

Function WaveCountOnes(wname)
	String wname
	
	NMDeprecatedAlert("WaveCountValue")

	return WaveCountValue(wname, 1)

End // WaveCountOnes

//*********************************************

Function DeleteNANs(wName, yname, xflag) 
	String wName
	String yname
	Variable xflag
	
	NMDeprecatedFatalError("WaveTransform")
	
	return NaN // NOT FUNCTIONAL

End // DeleteNANs

//*********************************************

Function NMSortWave(wName, dName, select, aValue, sValue, nValue)
	String wName
	String dName
	Variable select
	Variable aValue, sValue, nValue
	
	Variable binaryOutput = 1
	
	STRUCT NMInequalityStructOld s
	
	NMInequalityStructConvert(select, aValue, sValue, nValue, s)
	
	if (!WaveExists($wName))
		return -1
	endif
		
	Duplicate /O $wName $dName
	
	Wave wtemp = $wName
	Wave dtemp = $dName
	
	if ((numtype(s.greaterThan) == 0) || (numtype(s.lessThan) == 0))
		dtemp = NMInequality(wtemp, greaterThan=s.greaterThan, lessThan=s.lessThan, binaryOutput=binaryOutput, deprecation=1)
	else
		dtemp = NaN
	endif
	
	return 0
	
End // NMSortWave

//*********************************************

Function NMComparisonOperator(wName, dName, select, aValue, sValue, nValue)
	String wName
	String dName
	Variable select
	Variable aValue
	Variable sValue
	Variable nValue
	
	Variable binaryOutput = 1
	
	STRUCT NMInequalityStructOld s
	
	NMInequalityStructConvert(select, aValue, sValue, nValue, s)
	
	if (!WaveExists($wName))
		return -1
	endif
		
	Duplicate /O $wName $dName
	
	Wave wtemp = $wName
	Wave dtemp = $dName
	
	if ((numtype(s.greaterThan) == 0) || (numtype(s.lessThan) == 0))
		dtemp = NMInequality(wtemp, greaterThan=s.greaterThan, lessThan=s.lessThan, binaryOutput=binaryOutput, deprecation=1)
	else
		dtemp = NaN
	endif
	
	return 0
	
End // NMComparisonOperator

//*********************************************

Function /S RemoveStrEndSpace(istring)
	String istring
	Variable icnt
	
	NMDeprecatedAlert("RemoveEnding")
	
	return RemoveEnding(istring, " ")

End // RemoveStrEndSpace

//*********************************************

Function /S StringReplace(inStr, replaceThisStr, withThisStr)
	String inStr
	String replaceThisStr
	String withThisStr
	
	NMDeprecatedAlert("ReplaceString")
	
	return ReplaceString(replaceThisStr, inStr, withThisStr)

End // StringReplace

//*********************************************

Function /S NMReplaceChar(replaceThisStr, inStr, withThisStr)
	String replaceThisStr
	String inStr
	String withThisStr
	
	NMDeprecatedAlert("ReplaceString")
	
	return ReplaceString(replaceThisStr, inStr, withThisStr)
	
End // NMReplaceChar

//*********************************************

Function StrSearchLax(str, findThisStr, start)
	String str
	String findThisStr
	Variable start
	
	NMDeprecatedAlert("strsearch")
	
	return strsearch(str, findThisStr, start, 2)

End // StrSearchLax

//*********************************************

Function /S ReverseList(listStr, listSepStr)
	String listStr, listSepStr
	
	NMDeprecatedAlert("NMReverseList")
	
	return NMReverseList(listStr, listSepStr)
	
End // ReverseList

//*********************************************

Function /S RemoveListFromList(itemList, listStr, listSepStr)
	String itemList, listStr, listSepStr
	
	NMDeprecatedAlert("RemoveFromList")

	return RemoveFromList(itemList, listStr, listSepStr)

End // RemoveListFromList

//*********************************************

Function WhichListItemLax(itemStr, listStr, listSepStr)
	String itemStr, listStr, listSepStr
	
	NMDeprecatedAlert("WhichListItem")
	
	Variable startIndex = 0
	Variable matchCase = 0
	
	return WhichListItem(itemStr , listStr , listSepStr, startIndex, matchCase)
	
End // WhichListItemLax

//*********************************************

Function /S ChangeListSep(strList, listSepStr)
	String strList
	String listSepStr
	
	NMDeprecatedAlert("ReplaceString")
	
	strswitch(listSepStr)
		case ";":
			return ReplaceString(",", strList, ";")
		case ",":
			return ReplaceString(";", strList, ",")
	endswitch
	
	return ""
	
End // ChangeListSep

//*********************************************

Function /S GetListItems(matchStr, strList, listSepStr)
	String matchStr
	String strList
	String listSepStr
	
	NMDeprecatedAlert("ListMatch")
	
	return ListMatch(strList, matchStr, listSepStr)

End // GetListItems

//*********************************************

Function /S MatchStrList(strList, matchStr)
	String strList
	String matchStr
	
	NMDeprecatedAlert("ListMatch")
	
	return ListMatch(strList, matchStr, ";")
	
End // MatchStrList

//*********************************************

Function /S NMCmdList(strList, varList)
	String strList, varList
	
	NMDeprecatedAlert("NMCmdStr")
	
	return NMCmdStr(strList, varList)

End // NMCmdList

//*********************************************

Function /S EPSCDF()

	return "root:Packages:NeuroMatic:EPSC:"
	
End // EPSCDF()

//*********************************************

Function /S EventDF()

	return "root:Packages:NeuroMatic:Event:"
	
End // EventDF

//*********************************************

Function /S FitDF()

	return "root:Packages:NeuroMatic:Fit:"
	
End // FitDF

//*********************************************

Function /S MainDF()

	return "root:Packages:NeuroMatic:Main:"
	
End // MainDF

//*********************************************

Function /S NMDF()

	return "root:Packages:NeuroMatic:"
	
End // NMDF

//*********************************************

Function /S SpikeDF()

	return "root:Packages:NeuroMatic:Spike:"
	
End // SpikeDF

//*********************************************

Function /S StatsDF()

	return "root:Packages:NeuroMatic:Stats:"
	
End // StatsDF

//*********************************************

Function NMPanelWidth()

	return NMPanelWidth

End // NMPanelWidth

//*********************************************

Function NMPanelHeight()

	return NMPanelHeight

End // NMPanelHeight

//*********************************************

Function NMPanelTabY()

	return NMPanelTabY

End // NMPanelTabY

//*********************************************

Function NMPanelFsize()

	return NMPanelFsize

End // NMPanelFsize

//*********************************************

Function /S EventPrefix(objName)
	String objName
	
	NMDeprecatedAlert("NMTabPrefix_Event")
	
	return NMTabPrefix_Event() + objName
	
End // EventPrefix

//*********************************************

Function /S FitPrefix(varName)
	String varName
	
	NMDeprecatedAlert("NMTabPrefix_Fit")
	
	return NMTabPrefix_Fit() + varName
	
End // FitPrefix

//*********************************************

Function /S MainPrefix(objName)
	String objName
	
	NMDeprecatedAlert("NMTabPrefix_Main")
	
	return NMTabPrefix_Main() + objName
	
End // MainPrefix

//*********************************************

Function /S SpikePrefix(objName)
	String objName
	
	NMDeprecatedAlert("NMTabPrefix_Spike")
	
	return NMTabPrefix_Spike() + objName
	
End // SpikePrefix

//*********************************************

Function /S StatsPrefix(objName)
	String objName
	
	NMDeprecatedAlert("NMTabPrefix_Stats")
	
	return NMTabPrefix_Stats() + objName
	
End // StatsPrefix

//*********************************************

Function AutoEvent()

	NMDeprecatedAlert("NMEventAuto")

	return NMEventAuto()

End // AutoEvent

//*********************************************

Function AutoFit()

	NMDeprecatedAlert("NMFitAuto")

	return NMFitAuto()

End // AutoFit

//*********************************************

//Function AutoSpike() // function name conflicts with Spike config variable

	//NMDeprecatedAlert("NMSpikeAuto")

	//return NMSpikeAuto()

//End // AutoSpike

//*********************************************

Function NMAutoStats()

	NMDeprecatedAlert("NMStatsAuto")

	return NMStatsAuto()

End // NMAutoStats

//*********************************************




