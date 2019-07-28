/*
 * Ball bearing pusher - parametric version
 * ========================================
 *
 * Creates a 3D printable objects that forces an axis or rod into a 
 * ball bearing. Much easier than doing this by hand...
 *
 * Created by Thomas Hessling <mail@dream-dimensions.de>. 
 * License: Creative Commons - Attribution - Non-Commercial - Share Alike
 *
 * https://www.dream-dimensions.de
 * https://www.thingiverse.com/thing:3068893
 *
 * ChangeLog:
 *  - Initial release (2018-08-28)
 *    model creation works, need to test final part dimensions
 *
 */
 
 
/*
 * Define the cable duct's final dimensions.
 * All values are millimetres. 
 */
/* [General settings] */
// Cable duct overall length
cd_length = 150;
// Cable duct width
cd_width = 15;
// Cable duct height
cd_height = 15;
// Number of fins
cd_fins = 15;
// Fin width (approximate)
cd_fin_width = 4;
// Shell thickness
cd_shell = 1.2;

// Which part to create?
part = "both"; // [duct:Cable duct,cover:Duct top cove,both:Both parts"]


/* [Advanced settings] */
// Mounting feature size
mf_length = 3;
// Mounting feature angle
mf_angle = 45;
// Mounting feature depth
mf_depth = 1;
// Mounting feature offset from top
mf_top_offset = 1;
// Tolerance between cover and duct
tol = 0.15;


/* [Hidden] */
// the color
col = [0.3,0.5,0.85];
// safety offset for boolean operations, prevents spurious surfaces
s = 0.01;
// smoothness
$fn = 128;

cd_fin_spacing = (cd_length - cd_fin_width) / cd_fins;
cd_slit_width = cd_fin_spacing - cd_fin_width;


print_part();

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
	assert(mf_angle > 0, "The angle must be greater than 0 deg.");
	assert(mf_depth*tan(90-mf_angle)*2 <= mf_length, 
		   "The mounting feature length is too small. Increase length or the angle.");
	polyp = [[0,0], 
			 [0,-mf_length], 
			 [mf_depth,-mf_length+mf_depth*tan(90-mf_angle)], 
			 [mf_depth,-mf_depth*tan(90-mf_angle)]];
	polygon(polyp);
}


/*
	Cut profile for the interior of the rectangle, taking into account the mounting feature.
*/
module inner_duct_profile()
{
	cd_hwidth = cd_width/2;
	polygon([[cd_hwidth-mf_depth-cd_shell, cd_height+s],
	 [cd_hwidth-mf_depth-cd_shell, cd_height-mf_length],
	 [cd_hwidth-cd_shell, cd_height-mf_length-mf_depth*tan(90-mf_angle)],
	 [cd_hwidth-cd_shell, cd_shell],
	 [0, cd_shell],
	 [0, cd_height+s]]);
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
				scale([cd_width, cd_height])
				translate([-0.5, 0])
				square(1, center=false);
				
				union() {
					translate([-cd_width/2-s, cd_height-mf_top_offset])
					clip_profile();
					
					translate([cd_width/2+s, cd_height-mf_top_offset])
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
	translate([cd_width/2+tol, cd_height-mf_top_offset, 0])
	mirror([1, 0])
	clip_profile();
	
	translate([-cd_width/2-tol, cd_height-mf_top_offset, 0])
	clip_profile();
	
	polygon([[cd_width/2+tol, cd_height-mf_top_offset-mf_length],
			 [cd_width/2+tol, cd_height+tol],
			 [-cd_width/2-tol, cd_height+tol],
			 [-cd_width/2-tol, cd_height-mf_top_offset-mf_length],
			 [-cd_width/2-tol-cd_shell, cd_height-mf_top_offset-mf_length],
			 [-cd_width/2-tol-cd_shell, cd_height+tol+cd_shell],
			 [cd_width/2+tol+cd_shell, cd_height+tol+cd_shell],
			 [cd_width/2+tol+cd_shell, cd_height-mf_top_offset-mf_length],
			]);
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
		linear_extrude(height=cd_length, center=false)
		create_duct_profile();
	

		union() {
			for (i = [0:cd_fins-1]) {
				translate([-cd_width/2-1, 3*cd_shell, i*cd_fin_spacing+cd_fin_width])
				cube([cd_width+2, cd_height+1, cd_fin_spacing-cd_fin_width]);
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
	rotate(90, [1, 0, 0])
	linear_extrude(height=cd_length, center=false)
	create_cover_profile();
}