# split AMBER atom names into parts
split_AMBER_atomnames <- function( STRING_input )
{
  VEC_first <- unlist( strsplit( STRING_input,
                                 split = "@" ) )
  VEC_second <- unlist( strsplit( VEC_first[ 1 ],
                                  split = "_" ) )
  return( list( resName = VEC_second[ 1 ],
                resNumber = as.numeric( VEC_second[ 2 ] ),
                atomName = VEC_first[ 2 ] ) )
}

# split GROMACS atom names into parts
split_GROMACS_atomnames <- function( STRING_input )
{
  STRING_residueName <- NA
  STRING_residueNumber <- NA
  STRING_atomName <- NA
  for( i in 1:nchar( STRING_input ) )
  {
    if( suppressWarnings( is.na( as.numeric( substr( STRING_input,
                                                     i,
                                                     i ) ) ) ) )
      next
    STRING_residueName <- substr( STRING_input,
                                  1,
                                  i - 1 )
    for( j in i:nchar( STRING_input ) )
    {
      if( suppressWarnings( !is.na( as.numeric( substr( STRING_input,
                                                        j,
                                                        j ) ) ) ) )
        next
      STRING_residueNumber <- substr( STRING_input,
                                      i,
                                      j - 1 )
      STRING_atomName <- substr( STRING_input,
                                 j,
                                 nchar( STRING_input ) )
      return( list( residueName = STRING_residueName,
                    residueNumber = STRING_residueNumber,
                    atomName = STRING_atomName ) )
    }
  }
}

# find nth occurence
find_Nth_occurrence <- function( target,
                                 phrase,
                                 startFrom = 1,
                                 numberMatch = 1)
{
  parts = unlist( strsplit( substring( target, startFrom ), phrase ) )
  if( length( parts ) < ( numberMatch + 1 ) )
    return( -1 )
  return( sum( nchar( parts[ 1:numberMatch ] ) ) + startFrom + ( numberMatch - 1 ) * nchar( phrase ) )
}

# load XPM file and convert it into a matrix
# WARNING: colors are not reported
load_XPM <- function( path )
{
  inputData <- readLines( path )
  if( inputData[ 1 ] != "/* XPM */" )
    stop( "Magic number in file does not match XPM definition!" )
  inputData <- inputData[ -1 ]
  MAT_result <- NULL
  INT_numberColumns <- NA
  INT_numberRows <- NA
  VEC_colors <- c()
  VEC_chars <- c()
  VEC_colorComments <- c()
  for( i in 1:length( inputData ) )
  {
    if( regexpr( "static char", inputData[ i ] ) != -1 )
    {
      STRING_header <- inputData[ i + 1 ]
      VEC_header <- as.numeric( unlist( strsplit( substr( STRING_header, 2, nchar( STRING_header ) - 2 ), "[[:space:]]+" ) ) )
      INT_numberColumns <- VEC_header[ 1 ]
      INT_numberRows <- VEC_header[ 2 ]
      INT_start <- i + 2
      for( j in INT_start:( INT_start + VEC_header[ 3 ] - 1 ) )
      {
        STRING_colBuffer <- substr( inputData[ j ],
                                    find_Nth_occurrence( inputData[ j ], '"' ) + 1,
                                    find_Nth_occurrence( inputData[ j ], '"', numberMatch = 2 ) - 1 )
        VEC_chars <- c( VEC_chars,
                        substr( STRING_colBuffer, 1, 1 ) )
        INT_commentStart <- find_Nth_occurrence( inputData[ j ], "/" )
        if( INT_commentStart != -1 )
        {
          STRING_commentBuffer <- substr( inputData[ j ],
                                          INT_commentStart + 1,
                                          find_Nth_occurrence( inputData[ j ], "/", numberMatch = 2 ) - 1 )
          VEC_colorComments <- c( VEC_colorComments,
                                  as.numeric( 
                                  substr( STRING_commentBuffer,
                                          find_Nth_occurrence( STRING_commentBuffer, '"' ) + 1,
                                          find_Nth_occurrence( STRING_commentBuffer, '"', numberMatch = 2 ) - 1 ) ) )
        }
      }
      INT_start <- i + 1 + VEC_header[ 3 ] + 1
      INT_addition <- 0
      for( j in INT_start:length( inputData ) )
      {
        if( substr( inputData[ j ], 1, 3 ) == "/* " )
        {
          INT_addition <- INT_addition + 1
          next
        }
        else
          break
      }
      INT_start = INT_start + INT_addition
      for( j in INT_start:( INT_start + VEC_header[ 2 ] - 1 ) )
      {
        STRING_buffer <- inputData[ j ]
        STRING_buffer <- substr( inputData[ j ], 2, VEC_header[ 1 ] + 1 )
        if( all( is.null( MAT_result ) ) )
          MAT_result <- matrix( unlist( strsplit( STRING_buffer, split = "" ) ),
                                nrow = 1 )
        else
          MAT_result <- rbind( MAT_result,
                               unlist( strsplit( STRING_buffer, split = "" ) ) )
      }
      break
    }
  }
  return( list( numberColumns = INT_numberColumns,
                numberRows = INT_numberRows,
                usedColors = VEC_colors,
                colorComments = VEC_colorComments,
                usedChars = VEC_chars,
                data = MAT_result ) )
}

# round properly
setNumberDigits <- function( VEC_values, digits )
{
  VEC_return <- c()
  for( i in 1:length( VEC_values ) )
    VEC_return <- c( VEC_return,
                     as.numeric( format( round( VEC_values[ i ],
                                                digits ),
                                         nsmall = digits ) ) )
  return( VEC_return )
}

# translate amino acids in the context of the GROMOS framework
translate_aminoacids <- function( input,
                                  switchMode )
{
  VEC_GROMOS_triple = c( "ALA", "ARG", "ASN",
                         "ASP", "ASPH", "CYS",
                         "CYSH", "CYS1", "CYS2",
                         "GLN", "GLU", "GLUH",
                         "GLY", "HIS", "HISA",
                         "HISB", "HISH", "ILE",
                         "LEU", "LYS", "LYSH",
                         "MET", "PHE", "PRO",
                         "SER", "THR", "TRP",
                         "TYR", "VAL" )
  VEC_canonical_triple = c( "ALA", "ARG", "ASN",
                            "ASP", "ASP", "CYS",
                            "CYS", "CYS", "CYS",
                            "GLN", "GLU", "GLU",
                            "GLY", "HIS", "HIS",
                            "HIS", "HIS", "ILE",
                            "LEU", "LYS", "LYS",
                            "MET", "PHE", "PRO",
                            "SER", "THR", "TRP",
                            "TYR", "VAL" )
  VEC_canonical_single = c( "A", "R", "N",
                            "D", "D", "C",
                            "C", "C", "C",
                            "Q", "E", "E",
                            "G", "H", "H",
                            "H", "H", "I",
                            "L", "K", "K",
                            "M", "F", "P",
                            "S", "T", "W",
                            "Y", "V" )
  VEC_return <- c()
  
  # read three letter code and return canonical single letter code
  if( switchMode == 1 )
    for( i in 1:length( input ) )
      VEC_return <- c( VEC_return,
                       ifelse( input[ i ] %in% VEC_GROMOS_triple,
                               VEC_canonical_single[ VEC_GROMOS_triple == input[ i ] ],
                               input[ i ] ) )
  #########
  
  # read GROMOS three lettercode and return canonical three letter code 
  if( switchMode == 2 )
    for( i in 1:length( input ) )
      VEC_return <- c( VEC_return,
                       ifelse( input[ i ] %in% VEC_GROMOS_triple,
                               VEC_canonical_triple[ VEC_GROMOS_triple == input[ i ] ],
                               input[ i ] ) )
  #########
  
  return( VEC_return )
}

# integrate over a curve
integrate_curve <- function( MAT_input )
{
  if( ncol( MAT_input ) < 2 )
    stop( paste( "Error: Number of columns in matrix not 2 or higher, but ",
                 ncol( MAT_input ), "!" ) )
  REAL_error <- NA
  if( ncol( MAT_input ) > 2 )
    REAL_error <- 0.0
  REAL_integral <- 0.0
  
  # add next integral and error to sums
  for( i in 2:nrow( MAT_input ) )
  {
    REAL_integral <- REAL_integral + ( ( MAT_input[ i, 1 ] - MAT_input[ i - 1, 1 ] ) *
                                         ( MAT_input[ i, 2 ] + MAT_input[ i - 1, 2 ] ) ) / 2
    if( ncol( MAT_input ) > 2 )
      REAL_error <- REAL_error + ( ( MAT_input[ i, 1 ] - MAT_input[ i - 1, 1 ] ) *
                                     ( MAT_input[ i, 3 ] + MAT_input[ i - 1, 3 ] ) ) / 2
  }
  #########
  
  return( list( integral = REAL_integral, error = REAL_error ) )
}

# get nice axis values
split_equidistant <- function( VEC_values,
                               n = 5,
                               BOOL_removeFirst = FALSE,
                               BOOL_removeLast = FALSE,
                               BOOL_roundDown = FALSE )
{
  
  # get spread and divide in "n" values
  lower_bound = round( VEC_values[[ 1 ]], digits = - ( log10( VEC_values[[ 2 ]] ) - 1 ) )
  upper_bound = round( VEC_values[[ 2 ]], digits = - ( log10( VEC_values[[ 2 ]] ) - 1 ) )
  VEC_return <- c( lower_bound )
  delta <- upper_bound - lower_bound
  it <- delta / ( n - 1 )
  for( i in 1:( n - 2 ) )
    VEC_return <- c( VEC_return, as.integer( lower_bound + it * i ) )
  VEC_return <- c( VEC_return, upper_bound )
  #########
  
  # apply afterwork (in case)
  if( BOOL_removeFirst )
    VEC_return <- VEC_return[ -1 ]
  if( BOOL_removeLast )
    VEC_return <- VEC_return[ -length( VEC_return ) ]
  if( BOOL_roundDown )
    VEC_return <- signif( VEC_return, digits = 0 )
  #########
  return( VEC_return )
}

# calculate the middle point in 2D coordinate system from a list of points
calculate_mid <- function( LIST_points )
{
  REAL_x = 0
  REAL_y = 0
  for( i in 1:length( LIST_points ) )
  {
    REAL_x <- REAL_x + LIST_points[[ i ]][[ 1 ]]
    REAL_y <- REAL_y + LIST_points[[ i ]][[ 2 ]]
  }
  return( c( ( REAL_x / length( LIST_points ) ),
             ( REAL_y / length( LIST_points ) ) ) )
}

# parse command line arguments
parse_arguments <- function( VEC_arguments )
{  
  VEC_return <- c()
  if( length( VEC_arguments ) < 1 )
  {
    return( VEC_return )
  }
  for( i in 1:length( VEC_arguments ) )
  {
    if( grepl( "=", VEC_arguments[ i ] ) )
    {
      VEC_splitted <- unlist( strsplit( VEC_arguments[ i ], "=", fixed = TRUE ) )
      curArgument <- new( "MDplot_argument", key = VEC_splitted[ 1 ], value = VEC_splitted[ 2 ] )
      VEC_return <- c( VEC_return, curArgument )
    }
    else
      stop( paste( "Error in argument parsing: string '", VEC_arguments[ i ], 
                   "' does not contain any equal sign." ) )
  }
  return( VEC_return )
}

# redo at some point
getListOfKeys <- function( LIST_arguments )
{
  VEC_keys <- c()
  for( i in 1:length( LIST_arguments ) )
    VEC_keys <- c( VEC_keys, slot( LIST_arguments[[ i ]], "key" ) )
  return( VEC_keys )
}

# check, whether a key <> value pair is set in input parameters
isKeySet <- function( arguments, STRING_key )
{
  VEC_keysList <- c()
  if( is.list( arguments ) )
    VEC_keysList <- getListOfKeys( arguments )
  else
    VEC_keysList <- arguments
  if( STRING_key %in% VEC_keysList )
    return( TRUE )
  return( FALSE )
}

# test, whether all required input arguments are given with the script call
testRequired <- function( VEC_required, LIST_provided )
{
  if( length( VEC_required ) >= 1 )
    for( i in 1:length( VEC_required ) )
      if( !isKeySet( LIST_provided, VEC_required[ i ] ) )
        stop( paste( "Error while checking the proper provision of all required parameters (",
                     VEC_required, "). One or more missing." ) )
}

# hack to get value of key-value pair (fix for release please)
getValue <- function( LIST_arguments, STRING_key )
{
  for( i in 1:length( LIST_arguments ) )
    if( slot( LIST_arguments[[ i ]], "key" ) == STRING_key )
      return( slot( LIST_arguments[[ i ]], "value" ) )
  stop( paste( "Error while looking for value related to argument key",
              STRING_key, "in list of keys." ) )
}

# get vector of files
getFiles <- function( STRING_input )
{
  VEC_return <- c()
  if( grepl( ",", STRING_input ) )
    VEC_return <- strsplit( STRING_input, ",", fixed = TRUE )
  else
    return( STRING_input )
  return( unlist( VEC_return ) )
}

# test, whether all provided arguments are also allowed or should be ignored instead
testAllowed <- function( VEC_allowed, LIST_provided )
{
  VEC_providedKeys <- getListOfKeys( LIST_provided )
  if( length( VEC_allowed ) >= 1 )
    for( i in 1:length( VEC_providedKeys ) )
      if( !( isKeySet( VEC_allowed, VEC_providedKeys[ i ] ) ) )
        warning( paste( "Warning while checking provided parameters, since parameter",
                        VEC_providedKeys[ i ],
                        "is not in the list of allowed parameters (",
                        paste( VEC_allowed, collapse = ', ' ),
                        ") and therefore will be ignored for this call." ) )
}

# plot the error segments
plot_segments <- function( MAT_values,
                           VEC_spread,
                           REAL_difference = 0.1,
                           col = "black" )
{
  par( new = TRUE )
  segments( MAT_values[ , 1 ], MAT_values[ , 2 ] - VEC_spread, MAT_values[ , 1 ],
            MAT_values[ , 2 ] + VEC_spread,
            col = col ) # vertical lines
  segments( MAT_values[ , 1 ] - REAL_difference, MAT_values[ , 2 ] - VEC_spread,
            MAT_values[ , 1 ] + REAL_difference, MAT_values[ , 2 ] - VEC_spread,
            col = col ) # horizontal bottom line
  segments( MAT_values[ , 1 ] - REAL_difference, MAT_values[ , 2 ] + VEC_spread,
            MAT_values[ , 1 ] + REAL_difference, MAT_values[ , 2 ] + VEC_spread,
            col = col ) # horizontal top line
}

# significant digits based on the error
get_sign_digits <- function( REAL_error )
{
  if( REAL_error > 1.0 )
    return( 0 )
  VEC_digits <- as.numeric( strsplit( as.character( REAL_error ),
                                      "" )[[ 1 ]][ -1:-2 ] )
  for( i in 1:length( VEC_digits ) )
    if( VEC_digits[ i ] != 0 )
      return( i )
  return( VEC_digits )
}

# fill the bins according to specification
fill_bins <- function( MAT_input,
                       INT_xbins = 100,
                       INT_ybins = 100,
                       VEC_xLim = NA,
                       VEC_yLim = NA )
{
  if( all( is.na( VEC_xLim ) ) )
    VEC_xLim <- c( floor( min( MAT_input[ , 1 ] ) ), ceiling( max( MAT_input[ , 1 ] ) ) )
  if( all( is.na( VEC_yLim ) ) )
    VEC_yLim <- c( floor( min( MAT_input[ , 2 ] ) ), ceiling( max( MAT_input[ , 2 ] ) ) )
  
  cutsX <- seq( from = VEC_xLim[ 1 ], to = VEC_xLim[ 2 ], length = INT_xbins + 1 )
  cutsY <- seq( from = VEC_yLim[ 1 ], to = VEC_yLim[ 2 ], length = INT_ybins + 1 )
  indicesX <- cut( MAT_input[ , 1 ], cutsX, include.lowest = TRUE)
  indicesY <- cut( MAT_input[ , 2 ], cutsY, include.lowest = TRUE)
  
  freq2D <- NA
  if( ncol( MAT_input ) == 2 )
  {
    freq2D[ is.na( freq2D ) ] <- 0
    freq2D <- tapply( MAT_input[ , 1 ], list( indicesX, indicesY ), base::length )
  } else {
    if( ncol( MAT_input ) == 3 )
    {
      freq2D <- tapply( MAT_input[ , 3 ], list( indicesX, indicesY ), mean )
    } else {
      stop( "Error because the number of columns in input matrix is not either two or three!" )
    }
  }
  
  return( list( xBins = cutsX,
                yBins = cutsY,
                freq2D = freq2D ) )
}

# print help information here
print_help <- function( STRING_functionName,
                        VEC_arguments,
                        VEC_descriptions )
{
  if( length( VEC_arguments ) != length( VEC_descriptions ) )
    stop( paste( "Could not print help for function '",
                 STRING_functionName,
                 "' since lengths of arguments and descriptions does not match!",
                 sep = "" ) )
  writeLines( "------------------------" )
  writeLines( paste( "Function: '",
                     STRING_functionName,
                     "'",
                     sep = "" ) )
  writeLines( "------------------------" )
  for( i in 1:length( VEC_arguments ) )
    writeLines( paste( "\t",
                       VEC_arguments[ i ],
                       ifelse( ( nchar( VEC_arguments[ i ] ) < 8 ), "\t\t\t", "\t\t" ),
                       VEC_descriptions[ i ],
                       sep = "" ) )
  writeLines( "------------------------" )
  writeLines( "Package: MDplot" )
  writeLines( "Author: christian.margreitter@gmail\n\n" )
}