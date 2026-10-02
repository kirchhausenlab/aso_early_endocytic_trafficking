// ============================================================================
// Multichannel stack registration
//
// This Fiji/ImageJ macro applies a precomputed affine transformation to
// Channel 2 of a three-channel 3D image stack using MultiStackReg.
//
// Before running:
//   1. Change the path below to the location of your transformation matrix.
//   2. Run the macro and select the folder containing the TIFF stacks.
//
// Output:
//   Registered three-channel TIFF stacks are saved in a "transformed"
//   subfolder within the selected input directory.
// ============================================================================


// Select the directory containing the TIFF stacks to be registered.
// Fiji will prompt the user to select the directory.
dir = getDirectory("Choose a Directory");

print(dir);

list_tif = getFileList(dir);
n_digits = 4;


// ============================================================================
// USER INPUT: CHANGE THIS PATH
//
// Change this path to the location of the affine transformation matrix
// used to register Channel 2 (560 nm) to the 640 nm reference channel.
//
// The transformation matrix should have been previously generated using
// MultiStackReg from images of a multichannel registration standard.
// ============================================================================
file_560 = ""; // add your path here


l = lastIndexOf(dir, "/");
dir_t = substring(dir, 0, l);

l = lastIndexOf(dir_t, "/");
dir_save = substring(dir_t, 0, l);


// Output directory.
// Registered images will be saved inside a "transformed" subfolder
// created within the selected input directory.
dir_save = dir;

File.makeDirectory(dir_save + "/transformed/");


// ============================================================================
// PROCESS IMAGES
// ============================================================================

// Process each TIFF file in the selected directory.
for(i = 0; i < list_tif.length; i++){

		open(dir + list_tif[i]);

		name = list_tif[i];

		getDimensions(width, height, channels, slices, frames);
		
		rename("operation");
		
		
		// --------------------------------------------------------------------
		// Split the three-channel image into individual channel stacks.
		// --------------------------------------------------------------------
		run("Split Channels");
		
		
		// ====================================================================
		// CHANNEL REGISTRATION
		//
		// Channel 2 corresponds to the 560 nm channel.
		// The affine transformation defined above is applied independently
		// to each Z-plane using MultiStackReg.
		// ====================================================================
		
		selectImage("C2-operation");
		
		
		// Convert the Channel 2 Z-stack into individual images.
		run("Stack to Images");
		
		
		// Apply the affine transformation to each Z-plane.
		for(j = 1; j < slices + 1; j++){
				
				n = IJ.pad(j, n_digits);	
				image_trans = "C2-operation-" + n;
				
				selectWindow(image_trans);
				
				run("MultiStackReg",
					"stack_1=" + image_trans +
					" action_1=[Load Transformation File]" +
					" file_1=[" + file_560 + "]" +
					" stack_2=None action_2=Ignore file_2=[] transformation=Affine");
		}
		
		
		// --------------------------------------------------------------------
		// Reassemble the transformed Z-planes into a stack.
		// --------------------------------------------------------------------
		run("Images to Stack", "use");
		rename("C2_transformed");
		
		
		// --------------------------------------------------------------------
		// Merge channels.
		//
		// Channel 1: original Channel 1
		// Channel 2: registered/transformed Channel 2
		// Channel 3: original Channel 3
		// --------------------------------------------------------------------
		run("Merge Channels...",
			"c1=C1-operation c2=C2_transformed c3=C3-operation create");
		
		
		// --------------------------------------------------------------------
		// Set channel display colors.
		// --------------------------------------------------------------------
		
		Stack.setChannel(1);
		run("Green");
		
		Stack.setChannel(2);
		run("Magenta");
		
		Stack.setChannel(3);
		run("Cyan");
		
		
		// --------------------------------------------------------------------
		// Display a central Z-plane.
		// --------------------------------------------------------------------
		Stack.setSlice(slices/2 + 1);
		
		
		// Define a region used for display contrast adjustment.
		makeRectangle(250, 250, 200, 200);
		
		
		// --------------------------------------------------------------------
		// Adjust display contrast independently for each channel.
		// This is used for visualization and does not alter the registration
		// transformation.
		// --------------------------------------------------------------------
		
		Stack.setChannel(1);
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(2);
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(3);
		run("Enhance Contrast", "saturated=0.35");
		
		
		// --------------------------------------------------------------------
		// Save the registered three-channel stack.
		// --------------------------------------------------------------------
		saveAs("Tiff", dir_save + "/transformed/" + name);


		// Close all open images before processing the next TIFF file.
		close("*");
}