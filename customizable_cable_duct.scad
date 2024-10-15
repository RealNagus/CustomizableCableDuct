/*
 * Parametric cable duct with cover
 * ========================================
 *
 * Parametric cable duct creator with OpenSCAD
 * Copyright (C) 2019  Thomas Hessling <mail@dream-dimensions.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.*
 * Create your own custom cable duct with desired dimensions and matching top cover.
 *
 * https://www.dream-dimensions.de
 * https://www.printables.com/model/20033-customizable-cable-duct
 *
 * Version: 1.2 (2022-05-22)
 *
 * ChangeLog:
 *  ## v1.3 (2024-10-06)
 *  ### Added (by CrazyRaph)
 *  - option added for cover with edge, to prevent shifting 
 *  - add a little recess on first/last fin when cd_cover_equalwidth == true
 *  - by adding recess there is an option to enlarge first/last fin
 *
 *  ## v1.2 (2022-05-22)
 *  ### Changes
 *  - Changed the default text and set it to disabled.
 *  ### Added
 *  - Implemented mounting holes designed by user "3dcase" on https://www.printables.com
 *    (https://www.printables.com/social/244030-3dcase/about)
 *
 *  ## v1.1a (2019-09-21)
 *  ### Changes
 *  - Changed the license to GPLv3.
 *
 *  ## v1.1  (2019-08-03)
 *  ### Added
 *	- Add some custom text to your duct's cover
 *  - Option to create a cover with the same width as the duct, for narrow places
 *
 *  ## v1.0  (2019-07-28)
 *  - model creation works, first print successful.
 */
 
 
/*
 * Define the cable duct's final dimensions.
 * All values are millimetres. 
 */
 

/* [General settings] */
// Cable duct overall length
cd_length = 100;
// Cable duct width
cd_width = 15;
// Cable duct height
cd_height = 15;
// Number of fins
cd_fins = 8;
// Fin width
cd_fin_width = 3;
// Shell thickness (should be a multiple of your nozzle diameter)
cd_shell = 1.2;
// Force equal cover width - no overlap
cd_cover_equalwidth = 0; // [0:false, 1:true]
// Remark: since this setting is also used for the length, cd_cover_equalsize would be more appropriate

// Create edge on cover to prevent shifting
cd_cover_edge = "none"; // [one:one side closed,both:both sides closed,none: both sides open]
//Resize the fins on one or both sides to make space for the recess
cd_fins_resize = 0; // [0:false, 1:true]

// Number of mounting holes
cd_hole_count = 3;
// Mounting hole diameter
cd_hole_diameter = 3.3;
// Mounting hole offset from the edge
cd_hole_offset = 10;

// Which part to create? Duct, cover or both.
part = "both"; // [duct:Cable duct,cover:Duct top cover,both:Both parts]

/* [Mounting feature settings] */
// Mounting feature height
mf_length = 2;
// Mounting feature angle 
mf_angle = 45;
// Mounting feature depth
mf_depth = 0.8;
// Mounting feature offset from top
mf_top_offset = 0.6;
// Tolerance between cover and duct
mf_top_tolerance = 0.15;

/* [Cover text] */
// Show the text?
text_enable = 0; // [0:false, 1:true]
// The text
text_string = "Cables inside";
// Engraving depth, should be a multiple of layer height
text_depth = 0.6;
// Scaling relative to duct width
text_scale = 0.5;
// The font to use
text_font = "DejaVu Sans";


/* [Hidden] */
// the color
col = [0.3,0.5,0.85];
// safety offset for boolean operations, prevents spurious surfaces
s = 0.01;

//length for cover with edges and without
cd_length_cover = cd_length 
        - (cd_cover_equalwidth && cd_cover_edge == "one" ? cd_shell:0) 
        - (cd_cover_equalwidth && cd_cover_edge == "both" ? 2*cd_shell:0)
        + (!cd_cover_equalwidth && cd_cover_edge == "one" ? mf_top_tolerance:0) 
        + (!cd_cover_equalwidth && cd_cover_edge == "both" ? 2*mf_top_tolerance:0);

//recalculate cd_fin_spacing for resizing first an last
cd_fin_spacing = ((cd_fins_resize && cd_cover_equalwidth ? cd_length_cover : cd_length) - cd_fin_width) / cd_fins;
cd_slit_width = cd_fin_spacing - cd_fin_width;

// we have to take care if only 1 or 0 holes are specified
// the "x = ? a : b" syntax must be used because variables defined/changed inside 
// an if() scope do not effect their value outside that scope
cd_hole_spacing = cd_hole_count > 1 ? (cd_length-2*cd_hole_offset)/(cd_hole_count-1) : (cd_hole_count == 1 ? cd_length/2 : 0);


// Create the part
render()
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
 Create each children and a mirrored version of it along the given axis.
 */
module create_and_mirror(axis)
{
	for (i=[0:$children-1]) {
		children(i);
		mirror(axis) children(i);
	}	
}



/*
	Generates a trapezoidal profile that serves as a mounting feature for a	cover.
*/
module clip_profile(forCover)
{
	// Make the the angle is properly defined and does not lead to geometry errors
	assert(mf_angle > 0, "The angle must be greater than 0 deg.");
	assert(mf_angle <= 90, "The angle cannot be greater than 90 deg.");
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
    depth_factor = cd_cover_equalwidth ? 2 : 1;

    polygon([[cd_hwidth-depth_factor*mf_depth-cd_shell, cd_height+s],
     [cd_hwidth-depth_factor*mf_depth-cd_shell, cd_height-mf_length-mf_top_offset],
     [cd_hwidth-cd_shell, cd_height-mf_length-mf_top_offset-depth_factor*mf_depth*tan(45)],
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
				
				if (cd_cover_equalwidth)
				{
					union() {
						create_and_mirror([1, 0]) {
							translate([-cd_width/2-s+cd_shell+mf_top_tolerance, cd_height-mf_top_offset])
							clip_profile();
							translate([-cd_width/2, cd_height-mf_top_offset])
							polygon([[0,mf_top_offset],
									 [cd_shell+mf_top_tolerance, mf_top_offset],
									 [cd_shell+mf_top_tolerance, -mf_length],
									 [cd_shell+mf_top_tolerance*(1-cos(mf_angle)), -mf_length-mf_top_tolerance*cos(mf_angle)],
									 [0, -mf_length-mf_top_tolerance*cos(mf_angle)]]);
						}
					}
					
				} else {
					union() {
						create_and_mirror([1,0]) {
							translate([-cd_width/2-s, cd_height-mf_top_offset])
							clip_profile();
						}
					}
				}
			}
		}
		union() {
			create_and_mirror([1,0]) {
                inner_duct_profile();
			}
		}
	}
}

/*
	Create the cover profile to be extruded.
*/
module create_cover_profile()
{
	union() {
        xoffset = cd_cover_equalwidth ? cd_shell+mf_top_tolerance : 0;
        
		create_and_mirror([1,0]) {
			translate([cd_width/2+mf_top_tolerance-xoffset, cd_height-mf_top_offset, 0])
			mirror([1, 0])
			clip_profile(1);
		}
		
		polygon([[cd_width/2+mf_top_tolerance-xoffset, cd_height-mf_top_offset-mf_length],
				 [cd_width/2+mf_top_tolerance-xoffset, cd_height+mf_top_tolerance],
				 [-cd_width/2-mf_top_tolerance+xoffset, cd_height+mf_top_tolerance],
				 [-cd_width/2-mf_top_tolerance+xoffset, cd_height-mf_top_offset-mf_length],
				 [-cd_width/2-mf_top_tolerance-cd_shell+xoffset, cd_height-mf_top_offset-mf_length],
				 [-cd_width/2-mf_top_tolerance-cd_shell+xoffset, cd_height+mf_top_tolerance+cd_shell],
				 [cd_width/2+mf_top_tolerance+cd_shell-xoffset, cd_height+mf_top_tolerance+cd_shell],
				 [cd_width/2+mf_top_tolerance+cd_shell-xoffset, cd_height-mf_top_offset-mf_length],
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
        // extrude the duct profile
		linear_extrude(height=cd_length, center=false)
		create_duct_profile();
        
        // create a series of boxes to cut through the extruded profile
        // also subtract cylinder of mounting holes
		union() {
            // boxes
			for (i = [0:cd_fins-1]) {
				translate([-cd_width/2-1, 3*cd_shell, i*cd_fin_spacing+cd_fin_width+((cd_fins_resize && cd_cover_equalwidth && cd_cover_edge != "none")?cd_shell:0)])
				cube([cd_width+2, cd_height+1, cd_fin_spacing-cd_fin_width]);
			}
            // mounting hole cylinders
            if (cd_hole_count > 1)
            {
                for (i = [0:cd_hole_count-1]) {
                    translate([0, 0, cd_hole_offset+i*cd_hole_spacing])
                    rotate([90, 0, 0])
                    cylinder(h=4*cd_shell, d=cd_hole_diameter, center=true, $fn=60);
                }
            } else if (cd_hole_count == 1) {
                translate([0, 0, cd_hole_spacing])
                rotate([90, 0, 0])
                cylinder(h=4*cd_shell, d=cd_hole_diameter, center=true, $fn=60);
            }
            // space for recess if equalwidth is on
            if (cd_cover_equalwidth && cd_cover_edge != "none") {
                translate([-cd_width/2, cd_height-mf_length-mf_top_tolerance-mf_top_offset,0])
                cube([cd_width,mf_length+mf_top_tolerance+mf_top_offset,cd_shell+mf_top_tolerance], center=false);
            }
            if (cd_cover_equalwidth && cd_cover_edge == "both") {
                translate([-cd_width/2, cd_height-mf_length-mf_top_tolerance-mf_top_offset,cd_length-cd_shell-mf_top_tolerance])
                cube([cd_width,mf_length+mf_top_tolerance+mf_top_offset,cd_shell+mf_top_tolerance*2], center=false);
            }

		}
	}
	
}


/*
	Create a cover for the duct.
*/
module create_cover() 
{
    //some variables for the cover
    y_off = (cd_cover_edge != "none" ? -cd_shell:0);
    c_width = (cd_cover_equalwidth ? cd_width : cd_width + 2*(cd_shell + mf_top_tolerance));
    
    color(col)
    union(){
        difference() {
            translate([2*cd_width, y_off, cd_height+mf_top_tolerance+cd_shell])
            rotate(180, [0, 1, 0])
            rotate(90, [1, 0, 0])
            linear_extrude(height=cd_length_cover, center=false)
            create_cover_profile();

            if (text_enable) {
                translate([2*cd_width, -cd_length_cover/2, -s+0.6])
                rotate(90, [0, 0, -1])
                rotate(180, [1, 0, 0])
                linear_extrude(height=text_depth, center=false)
                text(text_string, cd_width*text_scale, text_font, valign="center", halign="center", $fn=32);
            }
        }
        //Create edges on Cover
        if (cd_cover_edge != "none") {
            translate([2*cd_width-c_width/2,-cd_shell,0])
            cube([c_width,cd_shell,cd_shell+mf_length+ mf_top_tolerance+mf_top_offset], center=false);
        }
        if (cd_cover_edge == "both") {
            translate([2*cd_width-c_width/2,-cd_length_cover - 2*cd_shell,0])
            cube([c_width,cd_shell,cd_shell+mf_length+ mf_top_tolerance+mf_top_offset], center=false);
        }
    }
}
