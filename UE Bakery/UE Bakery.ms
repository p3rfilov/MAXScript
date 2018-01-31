/*---------------------------------------------------------------
Name: UE Bakery

Description:
A set of tools for optimizing, unwrapping and preparing all scene objects
for rendering to texture and/or importing into Unreal Engine

Author: Andrej Perfilov [perfilov3d.com]
Date: 20-01-2018
*/---------------------------------------------------------------

---------------------------------------------- INCLUDES ----------------------------------------------

includeLocation = getFilenamePath (getThisScriptFilename()) + "includes\\"
filein (includeLocation + "functions.ms")
filein (includeLocation + "optimizeRollout.ms")
filein (includeLocation + "unwrapRollout.ms")
filein (includeLocation + "sceneCleanRollout.ms")
	
-----------------------------------------------------------------------------------------------------------
	
try(closeRolloutFloater UEbakery)catch()
UEbakery = newRolloutFloater "UE Bakery" 186 550 
addRollout sceneCleanRollout UEbakery
addRollout optimizeRollout UEbakery rolledUp:true
addRollout unwrapRollout UEbakery rolledUp:true

