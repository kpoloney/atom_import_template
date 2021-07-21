# Function takes original sfu description csv and the field mapping csv as parameters
# returns data in atom template form
transform_template <- function(sfu, map){
  
  # Name formatting
  names(map) <- c("atom", "sfu_fields")
  names(sfu)[1] <- "Fonds"
  names(sfu) <- gsub('\\.', '_', names(sfu))
  sfu <- subset(sfu, !is.na(sfu$Fonds)) 
  map$sfu_fields <- gsub('\\s', '_', map$sfu_fields)
  
  # Create empty df to hold atom template data
  atom_template <- as.data.frame(matrix(ncol = length(map$atom), nrow = nrow(sfu)))
  names(atom_template) <- as.character(map$atom)
  atom_used <- subset(map, !is.na(map$sfu_fields))
  
  for (i in 1:nrow(sfu)) {
    
    for (j in 1:nrow(atom_used)) {
      
      if (!grepl("^\\[", atom_used$sfu_fields[j])) {
        
        atom_template[i, atom_used$atom[j]]  <-  sfu[i, atom_used$sfu_fields[j]]
        
      } else if (grepl('=', atom_used$sfu_fields[j])) {
        
        atom_template[i, atom_used$atom[j]] <- gsub("^\\[=(.*)]$", "\\1", atom_used$sfu_fields[j])
        
      } else if (atom_used$atom[j] == "levelOfDescription"){
        
        atom_template$levelOfDescription[i] <- names(sfu)[which.max(is.na(sfu[i, 1:6]))-1]
        
      } else if (atom_used$atom[j] == "qubitParentSlug"){
        
        temp <- gsub("(f-\\d+-\\d+-\\d+)-\\d+-\\d", "\\1", sfu$Ref_code[i], ignore.case = T)
        
        atom_template$qubitParentSlug[i] <- gsub("(f-\\d+-\\d+-\\d+)-\\d+-\\d", "\\1", sfu$Ref_code[i], ignore.case = T)
        
      }
    }
  }
  
  atom_template
  
}

