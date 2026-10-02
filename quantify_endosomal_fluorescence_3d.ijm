// ============================================================================
// 3D endosomal fluorescence quantification
//
// This Fiji/ImageJ macro uses a Channel 2 (C2) binary mask to define and
// segment 3D objects. The same C2-defined objects are then used to quantify:
//
//   - Object volume
//   - Mean fluorescence intensity in Channel 2
//   - Mean fluorescence intensity in Channel 1
//   - Intersection with the Channel 1 binary mask
//
// The macro also generates merged multichannel images for visualization
// and quality control.
//
// Required input folders:
//   <experiment>_c1/
//   <experiment>_c1_mask/
//   <experiment>_c2/
//   <experiment>_c2_mask/
//   <experiment>_roi/
//
// Requirements:
//   - Fiji/ImageJ
//   - 3D ImageJ Suite / 3D Manager
//
// Before running:
//   1. Add the path containing the experiment folders below.
//   2. Specify the folder, if applicable.
//   3. Specify the experiment name.
//   4. Set the background values for Channels 1 and 2.
//
// ============================================================================


// ============================================================================
// USER INPUT
// ============================================================================

// Path containing the experiment folders.
path = ""; // add your path here


// Optional additional folder within the path.
// Leave empty if the experiment folders are directly inside "path".
folder = "";


// Experiment name.
// The macro expects the corresponding _c1, _c1_mask, _c2, _c2_mask,
// and _roi folders to use this experiment name.
experiment = "CO_U2OS_pHD488_dex640_control_001_T120";


// Background fluorescence values.
ch1_back = 101;
ch2_back = 103;


// ============================================================================
// OUTPUT DIRECTORIES
// ============================================================================

// Directory for 3D segmentation and quantification results.
save_directory = path + folder + "/" + experiment + "_c2_quantification_c1/";
File.makeDirectory(save_directory);


// Directory for merged images used for visualization / quality control.
save_merged = path + folder + "/" + experiment + "_merged_c2_primary_c1/";
File.makeDirectory(save_merged);


// ============================================================================
// INPUT DIRECTORIES
// ============================================================================

// Channel 1 raw fluorescence images.
c1_path = path + folder + experiment + "_c1/";

// Channel 1 binary masks.
c1_mask_path = path + folder + experiment + "_c1_mask/";

// Channel 2 raw fluorescence images.
c2_path = path + folder + experiment + "_c2/";

// Channel 2 binary masks used to define the primary 3D objects.
c2_mask_path = path + folder + experiment + "_c2_mask/";

// ROI files.
roi_path = path + folder + experiment + "_roi/";


// ============================================================================
// BUILD FILE LISTS
// ============================================================================

// Get all files from the C2 mask directory.
list_c2_mask = getFileList(c2_mask_path);

list_c2_raw = newArray(list_c2_mask.length);
list_roi = newArray(list_c2_mask.length);

list_c1_mask = newArray(list_c2_mask.length);
list_c1_raw = newArray(list_c2_mask.length);


print(c2_mask_path);
print(list_c2_mask.length);


// ============================================================================
// INITIALIZE ARRAYS FOR QUANTIFICATION RESULTS
// ============================================================================

// Arrays used to combine measurements from all segmented 3D objects.
volume = newArray(10000);
mean_ch2 = newArray(10000);
mean_ch1 = newArray(10000);
volume_intersec_mask = newArray(10000);

nb_index = newArray(1000);

w = 0;


// ============================================================================
// GENERATE MATCHING RAW-IMAGE AND ROI FILENAMES
// ============================================================================

for(i = 0; i < list_c2_mask.length; i = i + 1){

	print(list_c2_mask[i]);

	index = indexOf(list_c2_mask[i], ".tif", 0);

	list_c2_raw[i] = substring(list_c2_mask[i], 0, index + 4);

	list_roi[i] = substring(list_c2_mask[i], 0, index + 4);
	list_roi[i] = list_roi[i] + "_RoiSet.zip";
	list_roi[i] = substring(list_roi[i], 3);

	print(list_c2_raw[i]);
	print(list_roi[i]);
}


// ============================================================================
// CLEAR ROI MANAGER
// ============================================================================

a = roiManager("count");

if (a > 0) {
	roiManager("Deselect");
	roiManager("Delete");
}


// ============================================================================
// COUNT ROIs
// ============================================================================

roi_count = newArray(list_c2_mask.length);

for (i = 1000; i < list_c2_mask.length; i++) {

	roiManager("Open", roi_path + list_roi[i]);

	roi_count[i] = roiManager("count");

	roiManager("Deselect");
	roiManager("Delete");

	print(roi_count[i]);
}


// ============================================================================
// 3D SEGMENTATION AND QUANTIFICATION
// ============================================================================

all_nb = 0;


// Process each C2 mask image.
for(i = 0; i < list_c2_mask.length; i = i + 1){


	// Currently processes one ROI per image.
	for(j = 0; j < 1; j = j + 1){


		// --------------------------------------------------------------------
		// OPEN CHANNEL 2 RAW IMAGE
		// --------------------------------------------------------------------

		open(c2_path + list_c2_raw[i]);

		nrois = roiManager("count");
		print(nrois);


		// --------------------------------------------------------------------
		// OPEN CHANNEL 2 MASK
		//
		// The C2 mask defines the primary 3D objects used throughout the
		// subsequent measurements.
		// --------------------------------------------------------------------

		open(c2_mask_path + list_c2_mask[i]);

		rename(list_c2_mask[i]);


		getDimensions(width, height, channels, slices, frames);


		// Configure the image as a 3D stack.
		run("Properties...",
			"channels=1 slices=" + frames +
			" frames=" + 1 +
			" pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000");

		run("8-bit");


		// --------------------------------------------------------------------
		// SEGMENT 3D OBJECTS FROM THE C2 MASK
		// --------------------------------------------------------------------

		run("3D Manager");

		lowThreshold = 128;

		Ext.Manager3D_Segment(lowThreshold, 255);

		Ext.Manager3D_AddImage();

		Ext.Manager3D_Count(nb_obj);


		if(nb_obj > 0){


			// Save the segmented 3D objects.
			Ext.Manager3D_Save(
				save_directory +
				"/Roi3D_" +
				list_c2_mask[i] +
				"_roi_" +
				j +
				".zip"
			);


			// Convert binary mask values from 0/255 to 0/1.
			selectWindow(list_c2_mask[i]);
			run("Divide...", "value=255 stack");


			// ----------------------------------------------------------------
			// QUANTIFY C2 MASK / OBJECT VOLUME
			// ----------------------------------------------------------------

			Ext.Manager3D_DeselectAll();

			Ext.Manager3D_Quantif();

			Ext.Manager3D_SaveResult(
				"Q",
				save_directory +
				"/" +
				list_c2_mask[i] +
				"_" +
				list_c2_mask[i] +
				"_roi_" +
				j +
				".csv"
			);

			Ext.Manager3D_CloseResult("Q");


			// Integrated density of the binary 0/1 C2 mask corresponds
			// to the number of voxels belonging to each segmented object.
			selectWindow(list_c2_mask[i]);

			for(nb = 0; nb < nb_obj; nb = nb + 1){

				Ext.Manager3D_Quantif3D(
					nb,
					"IntDen",
					quantif
				);

				volume[nb + all_nb] = quantif;
			}


			// ----------------------------------------------------------------
			// QUANTIFY CHANNEL 2 RAW FLUORESCENCE
			// ----------------------------------------------------------------

			// Subtract the predefined Channel 2 background.
			selectWindow(list_c2_raw[i]);

			run("Subtract...", "value=" + ch2_back + " stack");


			// Quantify the C2 raw image using the C2-defined 3D objects.
			Ext.Manager3D_DeselectAll();

			Ext.Manager3D_Quantif();

			Ext.Manager3D_SaveResult(
				"Q",
				save_directory +
				"/" +
				list_c2_mask[i] +
				"_" +
				list_c2_raw[i] +
				"_roi_" +
				j +
				".csv"
			);

			Ext.Manager3D_CloseResult("Q");


			// Store mean C2 fluorescence for every segmented object.
			selectWindow(list_c2_raw[i]);

			for(nb = 0; nb < nb_obj; nb = nb + 1){

				Ext.Manager3D_Quantif3D(
					nb,
					"Mean",
					quantif
				);

				mean_ch2[nb + all_nb] = quantif;
			}


			// ----------------------------------------------------------------
			// CHANNEL 1 MASK
			//
			// Generate the matching C1 mask filename and quantify its
			// intersection with each C2-defined 3D object.
			// ----------------------------------------------------------------

			list_c1_mask[i] = substring(list_c2_mask[i], 3);
			list_c1_mask[i] = "C1-" + list_c1_mask[i];

			print(list_c1_mask[i]);

			open(c1_mask_path + list_c1_mask[i]);

			rename(list_c1_mask[i]);


			run("Properties...",
				"channels=1 slices=" + frames +
				" frames=" + 1 +
				" pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000");

			run("8-bit");


			// Expand the C1 mask by one pixel.
			run("Maximum...", "radius=1");


			// Convert binary mask values from 0/255 to 0/1.
			run("Divide...", "value=255 stack");


			// Quantify the C1 mask within the C2-defined 3D objects.
			Ext.Manager3D_DeselectAll();

			Ext.Manager3D_Quantif();

			Ext.Manager3D_SaveResult(
				"Q",
				save_directory +
				"/" +
				list_c2_mask[i] +
				"_" +
				list_c1_mask[i] +
				"_roi_" +
				j +
				".csv"
			);

			Ext.Manager3D_CloseResult("Q");


			// Mean intensity of the binary C1 mask within each C2 object
			// represents the fraction of that C2-defined object intersecting
			// the C1 mask.
			selectWindow(list_c1_mask[i]);

			for(nb = 0; nb < nb_obj; nb = nb + 1){

				Ext.Manager3D_Quantif3D(
					nb,
					"Mean",
					quantif
				);

				volume_intersec_mask[nb + all_nb] = quantif;
			}


			// ----------------------------------------------------------------
			// PREPARE C2 RAW AND MASK IMAGES FOR MERGED QC IMAGE
			// ----------------------------------------------------------------

			selectWindow(list_c2_raw[i]);

			run("Duplicate...", "duplicate");

			rename(list_c2_raw[i] + "_dup");


			selectWindow(list_c2_mask[i]);

			run("Duplicate...", "duplicate");

			rename(list_c2_mask[i] + "_dup");

			run("16-bit");


			selectWindow(list_c1_mask[i]);

			run("Duplicate...", "duplicate");

			rename(list_c1_mask[i] + "_dup");

			run("16-bit");


			// ----------------------------------------------------------------
			// OPEN CHANNEL 1 RAW IMAGE
			// ----------------------------------------------------------------

			list_c1_raw[i] = substring(list_c2_raw[i], 3);
			list_c1_raw[i] = "C1-" + list_c1_raw[i];

			print(list_c1_raw[i]);

			open(c1_path + list_c1_raw[i]);


			// Subtract the predefined Channel 1 background.
			run("Subtract...", "value=" + ch1_back + " stack");

			rename(list_c1_raw[i]);


			// ----------------------------------------------------------------
			// QUANTIFY CHANNEL 1 RAW FLUORESCENCE
			//
			// The same C2-defined 3D objects are applied to the C1 raw image.
			// ----------------------------------------------------------------

			selectWindow(list_c1_raw[i]);

			Ext.Manager3D_DeselectAll();

			Ext.Manager3D_Quantif();

			Ext.Manager3D_SaveResult(
				"Q",
				save_directory +
				"/" +
				list_c2_mask[i] +
				"_" +
				list_c1_raw[i] +
				"_roi_" +
				j +
				".csv"
			);

			Ext.Manager3D_CloseResult("Q");


			// Store mean C1 fluorescence for every C2-defined object.
			selectWindow(list_c1_raw[i]);

			for(nb = 0; nb < nb_obj; nb = nb + 1){

				Ext.Manager3D_Quantif3D(
					nb,
					"Mean",
					quantif
				);

				mean_ch1[nb + all_nb] = quantif;
			}


			// Delete the current objects from 3D Manager.
			Ext.Manager3D_DeselectAll();
			Ext.Manager3D_Delete();


			// ----------------------------------------------------------------
			// CREATE MERGED IMAGE FOR VISUALIZATION / QUALITY CONTROL
			// ----------------------------------------------------------------

			selectWindow(list_c1_raw[i]);

			run("Duplicate...", "duplicate");

			rename(list_c1_raw[i] + "_dup");


			// Merge:
			//   C1 = Channel 1 raw
			//   C2 = Channel 2 raw
			//   C3 = Channel 1 mask
			//   C4 = Channel 2 mask
			run(
				"Merge Channels...",
				"c1=[" + list_c1_raw[i] + "_dup]" +
				" c2=[" + list_c2_raw[i] + "_dup]" +
				" c3=[" + list_c1_mask[i] + "_dup]" +
				" c4=[" + list_c2_mask[i] + "_dup]" +
				" create"
			);


			// Set mask display colors.
			Stack.setChannel(3);
			run("Green");

			Stack.setChannel(4);
			run("Red");


			merged_name = substring(list_c2_raw[i], 3);


			// Save merged QC image.
			saveAs(
				"Tiff",
				save_merged +
				merged_name +
				"_merged_ROI_" +
				j +
				".tif"
			);


			// Close all images before processing the next dataset.
			close("*");


			// Keep track of the total number of segmented objects.
			all_nb = nb_obj + all_nb;

			nb_index[w] = nb;

			w = w + 1;


			// Clear ROI Manager.
			a = roiManager("count");

			if (a > 0) {
				roiManager("Deselect");
				roiManager("Delete");
			}

		}
	}
}


close("*");


// ============================================================================
// COMBINE ALL OBJECT MEASUREMENTS INTO THE FIJI RESULTS TABLE
// ============================================================================

w = 0;
l = 0;


for (i = 0; i < list_c2_mask.length; i++) {

	for(j = 0; j < 1; j = j + 1){

		for(k = 0; k < nb_index[w]; k = k + 1){

			setResult("Name", l, list_c2_mask[i]);

			setResult("ROI", l, j);

			setResult("Object", l, k);

			setResult("volume", l, volume[l]);

			setResult("mean_ch2", l, mean_ch2[l]);

			setResult("mean_ch1", l, mean_ch1[l]);

			setResult(
				"volume_intersec",
				l,
				volume_intersec_mask[l]
			);

			l = l + 1;
		}

		w = w + 1;
	}
}


// ============================================================================
// SAVE MASTER RESULTS TABLE
//
// The final CSV contains one row for each C2-defined 3D object with:
//   - Image name
//   - ROI
//   - Object number
//   - Object volume
//   - Mean Channel 2 fluorescence
//   - Mean Channel 1 fluorescence
//   - Fraction intersecting the Channel 1 mask
// ============================================================================

selectWindow("Results");

saveAs(
	"results",
	path +
	folder +
	experiment +
	"_c2_applied_in_c1.csv"
);


selectWindow("Results");
run("Close");