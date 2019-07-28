/*
 * Parametric cable duct with cover
 * ========================================
 *
 * Create your own custom cable duct with desired dimensions and matching top cover.
 *
 * Created by Thomas Hessling <mail@dream-dimensions.de>. 
 * License: Creative Commons - Attribution - Non-Commercial - Share Alike
 *
 * https://www.dream-dimensions.de
 * https://www.thingiverse.com/thing:3775502
 *
 * ChangeLog:
 *  - Initial release (2019-07-28)
 *    model creation works, first print successful.
 */
 
 
/*
 * Define the cable duct's final dimensions.
 * All values are millimetres. 
 */
 

/* [General settings] */
// Cable duct overall length
cable_duct_length = 70;
// Cable duct width
cable_duct_width = 10;
// Cable duct height
cable_duct_height = 10;
// Number of fins
cable_duct_fins = 8;
// Fin width
cable_duct_fin_width = 3;
// Shell thickness (should be a multiple of your nozzle diameter)
cable_duct_shell = 1.2;

// Which part to create? Duct, cover or both.
part = "both"; // [duct:Cable duct,cover:Duct top cover,both:Both parts]


/* [Mounting feature settings] */
// Mounting feature height
mounting_feature_length = 2;
// Mounting feature angle 
mounting_feature_angle = 45;
// Mounting feature depth
mounting_feature_depth = 0.8;
// Mounting feature offset from top
mounting_feature_top_offset = 0.6;
// Tolerance between cover and duct
mounting_feature_tolerance = 0.15;

/* [Hidden] */
// the color
col = [0.3,0.5,0.85];
// safety offset for boolean operations, prevents spurious surfaces
s = 0.01;

cd_fin_spacing = (cable_duct_length - cable_duct_fin_width) / cable_duct_fins;
cd_slit_width = cd_fin_spacing - cable_duct_fin_width;


// Create the part
print_part();



/*
	Create the part based on the part-variable: duct, cover or both
*/
module print_part()
{
	if (part == "duct") {
		create_duct();		
	} else if (part == "cover") {
		create_cover();		
	} else if (part == "both") {
		create_duct();
		create_cover();
	}
}


/*
	Generates a trapezoidal profile that serves as a mounting feature for a	cover.
*/
module clip_profile()
{
	// Make the the angle is properly defined and does not lead to geometry errors
	assert(mounting_feature_angle > 0, "The angle must be greater than 0 deg.");
	assert(mounting_feature_angle <= 90, "The angle cannot be greater than 90 deg.");
	assert(mounting_feature_depth*tan(90-mounting_feature_angle)*2 <= mounting_feature_length, 
		   "The mounting feature length is too small. Increase length or the angle.");
	
	polyp = [[0,0], 
			 [0,-mounting_feature_length], 
			 [mounting_feature_depth,-mounting_feature_length+mounting_feature_depth*tan(90-mounting_feature_angle)], 
			 [mounting_feature_depth,-mounting_feature_depth*tan(90-mounting_feature_angle)]];
	polygon(polyp);
}


/*
	Cut profile for the interior of the rectangle, taking into account the mounting feature.
*/
module inner_duct_profile()
{
	cd_hwidth = cable_duct_width/2;
	polygon([[cd_hwidth-mounting_feature_depth-cable_duct_shell, cable_duct_height+s],
	 [cd_hwidth-mounting_feature_depth-cable_duct_shell, cable_duct_height-mounting_feature_length-mounting_feature_top_offset],
	 [cd_hwidth-cable_duct_shell, cable_duct_height-mounting_feature_length-mounting_feature_top_offset-mounting_feature_depth*tan(45)],
	 [cd_hwidth-cable_duct_shell, cable_duct_shell],
	 [0, cable_duct_shell],
	 [0, cable_duct_height+s]]);
}

/*
	The duct's cross-sectional profile, used in an extrusion.
*/
module create_duct_profile()
{
	/*
		Basic shape: rectangle
		Subtract the mounting features from it, and also the interior bulk.
		This then serves as an extrusion profile.	
	*/
	difference() {
		difference() {
			difference() {
				scale([cable_duct_width, cable_duct_height])
				translate([-0.5, 0])
				square(1, center=false);
				
				union() {
					translate([-cable_duct_width/2-s, cable_duct_height-mounting_feature_top_offset])
					clip_profile();
					
					translate([cable_duct_width/2+s, cable_duct_height-mounting_feature_top_offset])
					mirror([1, 0])
					clip_profile();
				}
			}
		}
		union() {
			inner_duct_profile();
			mirror([1, 0])
			inner_duct_profile();
		}
	}

}

/*
	Create the cover profile to be extruded.
*/
module create_cover_profile()
{
	union() {
		translate([cable_duct_width/2+mounting_feature_tolerance, cable_duct_height-mounting_feature_top_offset, 0])
		mirror([1, 0])
		clip_profile();
		
		translate([-cable_duct_width/2-mounting_feature_tolerance, cable_duct_height-mounting_feature_top_offset, 0])
		clip_profile();
		
		polygon([[cable_duct_width/2+mounting_feature_tolerance, cable_duct_height-mounting_feature_top_offset-mounting_feature_length],
				 [cable_duct_width/2+mounting_feature_tolerance, cable_duct_height+mounting_feature_tolerance],
				 [-cable_duct_width/2-mounting_feature_tolerance, cable_duct_height+mounting_feature_tolerance],
				 [-cable_duct_width/2-mounting_feature_tolerance, cable_duct_height-mounting_feature_top_offset-mounting_feature_length],
				 [-cable_duct_width/2-mounting_feature_tolerance-cable_duct_shell, cable_duct_height-mounting_feature_top_offset-mounting_feature_length],
				 [-cable_duct_width/2-mounting_feature_tolerance-cable_duct_shell, cable_duct_height+mounting_feature_tolerance+cable_duct_shell],
				 [cable_duct_width/2+mounting_feature_tolerance+cable_duct_shell, cable_duct_height+mounting_feature_tolerance+cable_duct_shell],
				 [cable_duct_width/2+mounting_feature_tolerance+cable_duct_shell, cable_duct_height-mounting_feature_top_offset-mounting_feature_length],
				]);
	}
}

/*
	Extrude the duct's cross-section profile, cut boxes in regular distance to create the
	"fins" and cut holes in the bottom to save material.
*/
module create_duct()
{
	color(col)
	rotate(90, [1, 0, 0])
	difference() {
		linear_extrude(height=cable_duct_length, center=false)
		create_duct_profile();
	

		union() {
			for (i = [0:cable_duct_fins-1]) {
				translate([-cable_duct_width/2-1, 3*cable_duct_shell, i*cd_fin_spacing+cable_duct_fin_width])
				cube([cable_duct_width+2, cable_duct_height+1, cd_fin_spacing-cable_duct_fin_width]);
			}
		}
	}
	
}


/*
	Create a cover for the duct.
*/
module create_cover() 
{
	color(col)
	translate([2*cable_duct_width, 0, cable_duct_height+mounting_feature_tolerance+cable_duct_shell])
	rotate(180, [0, 1, 0])
	rotate(90, [1, 0, 0])
	linear_extrude(height=cable_duct_length, center=false)
	create_cover_profile();
}
