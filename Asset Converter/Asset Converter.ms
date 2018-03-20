/*---------------------------------------------------------------
Name: Asset Converter

Description:
Converts scene bitmaps to a target format (PSD to PNG for now)
Makes use of fileConverter stand-alone executable package (included)

Requirements:
Photoshop

Author: Andrej Perfilov [perfilov3d.com]
Date: 20-03-2018
*/---------------------------------------------------------------

---------------------------------------------- INCLUDES ----------------------------------------------

includeLocation = getFilenamePath (getThisScriptFilename()) + "includes\\"
filein (includeLocation + "updateBuild.ms")
	
-----------------------------------------------------------------------------------------------------------

try(destroyDialog assetConversion)catch()
rollout assetConversion "Converting PSD assets..." width:328 height:72
(
	progressBar 'pb1' "ProgressBar" pos:[8,8] width:312 height:24 align:#left color:green
	button 'btn_cancel' "Cancel" pos:[104,40] width:120 height:24 align:#left

	local sourceDir = getFilenamePath (getThisScriptFilename()) + "\\fileConverter"
	local localDir = (getdir #downloads) + "\\fileConverter"
	local converterEXE = localDir + "\\fileConverter.exe"
	local sorceFormat = "psd"
	local targetFormat = "png"
	local stopped = False
	
	fn getAssets =
	(
		ATSOps.visible = true
		ATSOps.Refresh()
		ATSOps.visible = false
		ATSOps.CheckNetworkPaths = true
		ATSOps.GetFilesByFileSystemStatus #Ok &assetsToConvert
		for i in assetsToConvert.count to 1 by -1 do
		(
			if toLower(getFilenameType assetsToConvert[i]) != ("."+sorceFormat) or \
			ATSOps.IsInputFile assetsToConvert[i] == false do deleteItem assetsToConvert i
		)
		ATSOps.CheckNetworkPaths = false
		return assetsToConvert
	)
	
	fn changeFileFormatPath file newFormat =
	(
		p = getFilenamePath file
		n = getFilenameFile file
		f = "." + newFormat
		targetFile = p + "\\" + n + f
		return targetFile
	)
	
	fn dispatchConvertCommand executable fileFormat fileArray =
	(
		cmd = executable + " "
		cmd += "\"" + fileFormat + "\" "
		for f in fileArray do
			cmd += "\"" + f + "\" "
		HiddenDOSCommand cmd donotwait:true
	)
	
	fn quit =
	(
		stopped = True
		try(destroyDialog assetConversion)catch()
	)
	
	on assetConversion open do
	(
		updateBuild sourceDir localDir
		assets = getAssets()
		if assets.count != 0 do
		(
			Yeap = queryBox "PSD bitmaps found in the scene.\nConvert to PNG?" title:"Asset Conversion" beep:false
			if (Yeap != undefined) and Yeap do
			(
				dispatchConvertCommand converterEXE targetFormat assets
				count = 0
				for i in assets where not stopped do
				(
					target = changeFileFormatPath i targetFormat
					while not stopped and not doesFileExist target do
					(
						sleep 0.5
						windows.processPostedMessages()
					)
					ATSOps.ClearSelection()
					ATSOps.SelectFiles i
					ATSOps.RetargetSelection target
					count += 1
					pb1.value = 100*count/assets.count
					windows.processPostedMessages()
				)
			)
		)
		quit()
	)
	on assetConversion close do
		quit()
	
	on btn_cancel pressed do
	(
		quit()
	)
)

createDialog assetConversion


