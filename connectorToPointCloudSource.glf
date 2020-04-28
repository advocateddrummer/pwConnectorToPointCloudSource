package require PWI_Glyph

# Create a connector selection mask.
set mask [pw::Display createSelectionMask -requireConnector {}];

#
# Use selected connector or prompt user for selection if nothing is selected at
# run time.
#
if { !([pw::Display getSelectedEntities -selectionmask $mask selection]) } {
  # No connector was selected at runtime; prompt for one now.

# Create a connector selection dialog.
if { ![pw::Display selectEntities \
       -selectionmask $mask \
       -description "Select connector(s) to use." \
     selection] } {

    puts "Error: Unsuccessfully selected connector(s)... exiting"
    exit
  }

}

set cons $selection(Connectors)

puts "Selected $cons for use."

foreach con $cons {
  puts "Converting $con into point sources..."
  # This seems like a better solution, but I am not sure how to properly
  # convert connectors into a line source entity.
  #set lineSource [pw::SourceCurve create]

  # Holds coordinates of nodes in connector.
  set xyzs [list]
  # Holds distances between nodes in connector.
  set lengths [list]
  # Holds average spacing of each edge around a node.
  set spacings [list]
  # Agglomerates the data required to create point cloud sources from points.
  set pointData [list]
  # TODO: I think I can eliminate this variable.
  set index 1

  # Handle first node/point.
  set xyz [$con getXYZ 1]
  lappend xyzs $xyz
  set previousLength [$con getLength 2]
  lappend lengths $previousLength
  lappend spacings $previousLength
  lappend pointData [list [pwu::Vector3 set [lindex $xyz 0] [lindex $xyz 1] [lindex $xyz 2]] [lindex $spacings 0] 0.95]

  # Get number of nodes/points on current connector.
  set numPoints [$con getPointCount]

  # Loop over interior nodes.
  for {set i 2} {$i < $numPoints} {incr i} {
    set xyz [$con getXYZ $i]
    lappend xyzs $xyz

    # Get length of edge 'ahead' of current node.
    set currentLength [$con getLength [expr {$i + 1}]]
    lappend lengths [expr {$currentLength - $previousLength}]

    # Average lengths of edges surrounding current node.
    lappend spacings [expr {0.5*([lindex $lengths $index] + [lindex $lengths [expr {$index - 1}]])}]
    set previousLength $currentLength

    # Build up point cloud source data.
    lappend pointData [list [pwu::Vector3 set [lindex $xyz 0] [lindex $xyz 1] [lindex $xyz 2]] [lindex $spacings $index] 0.95]
    incr index
  }

  # Handle last point
  set xyz [$con getXYZ $numPoints]
  lappend xyzs $xyz
  set previousLength [$con getLength [expr {$numPoints - 1}]]
  set currentLength [$con getLength $numPoints]
  lappend lengths [expr {$currentLength - $previousLength}]
  lappend spacings [expr {0.5*([lindex $lengths $index] + [lindex $lengths [expr {$index - 1}]])}]
  lappend pointData [list [pwu::Vector3 set [lindex $xyz 0] [lindex $xyz 1] [lindex $xyz 2]] [lindex $spacings $index] 0.95]

  # Create and initialize point cloud source.
  set pointCloud [pw::SourcePointCloud create]
  $pointCloud addPoints $pointData

  #puts "xyzs: $xyzs"
  #puts "lengths: $lengths"
  #puts "spacings: $spacings"
  #puts ""
  #puts "\tpointData: $pointData"
}

# vim: set ft=tcl:
