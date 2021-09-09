# Function takes original description csv and the field mapping csv as parameters
# returns data in atom template form
transform_template <- function(origin, map, inst){
  
  # Name formatting
  names(map) <- c("atom", "origin_fields")
  names(origin) <- gsub("^\\.\\.", "", names(origin)) # this error occurs from UTF-8 BOM on ms apps
  
  # SFU-specific formatting
  if (inst == "SFU Archives") {
    names(origin)[1] <- "Fonds"
    names(origin) <- gsub('\\.', '_', names(origin))
    origin <- subset(origin, !is.na(origin$Fonds)) 
    map$origin_fields <- gsub('\\s', '_', map$origin_fields)
  }
  
  # Create empty df to hold atom template data
  atom_template <- as.data.frame(matrix(ncol = length(map$atom), nrow = nrow(origin)))
  names(atom_template) <- as.character(map$atom)
  atom_used <- subset(map, !is.na(map$origin_fields))
  
  for (i in 1:nrow(origin)) {
    
    for (j in 1:nrow(atom_used)) {
      
      if (!grepl("^\\[", atom_used$origin_fields[j])) {
        
        atom_template[i, atom_used$atom[j]]  <-  origin[i, atom_used$origin_fields[j]]
        
      } else if (grepl('=', atom_used$origin_fields[j])) {
        
        atom_template[i, atom_used$atom[j]] <- gsub("^\\[=(.*)]$", "\\1", atom_used$origin_fields[j])
        
      } else if (atom_used$atom[j] == "levelOfDescription" & inst == "SFU Archives"){
        
        atom_template$levelOfDescription[i] <- names(origin)[which.max(is.na(origin[i, 1:6]))-1]
        
      } else if (atom_used$atom[j] == "qubitParentSlug" & inst == "SFU Archives"){
        
        atom_template$qubitParentSlug[i] <- gsub("(f-\\d+-\\d+-\\d+)-\\d+-\\d", "\\1", origin$Ref_code[i], ignore.case = T)
        
      }
    }
  }
  
  atom_template
  
}

