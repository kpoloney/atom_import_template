# Function takes original description csv and the field mapping csv as parameters
# returns data in atom template form
transform_template <- function(origin, map, inst){
  
  # Name formatting
  names(map) <- c("atom", "origin_fields")
  names(origin) <- gsub("^\\.\\.", "", names(origin)) # this error occurs from UTF-8 BOM on ms apps
  
  # SFU-specific formatting
  if (inst == "SFU Archives") {
    names(origin)[grep("fonds", names(origin), ignore.case=T)] <- "Fonds"
    names(origin) <- gsub('\\.', '_', names(origin))
    origin <- subset(origin, !is.na(origin$Fonds)) 
    map$origin_fields <- ifelse(!grepl("^\\[", map$origin_fields), 
                                gsub('\\s', '_', map$origin_fields), map$origin_fields)
  }

  # Create empty df to hold atom template data
  atom_template <- as.data.frame(matrix(ncol = length(map$atom), nrow = nrow(origin)))
  names(atom_template) <- as.character(map$atom)
  atom_used <- subset(map, !is.na(map$origin_fields))
  
  #Make sure all expected columns are in the original data
  atom_used <- subset(atom_used, atom_used$origin_fields %in% names(origin) | 
                        grepl("^\\[", atom_used$origin_fields))
  
  # Map for everyone else  
  for (i in 1:nrow(origin)) {
    for (j in 1:nrow(atom_used)) {
      if (atom_used$origin_fields[j] == atom_used$atom[j]) {
        atom_template[i, atom_used$atom[j]] <- origin[i, atom_used$atom[j]]
      }
      
      if (!grepl("^\\[", atom_used$origin_fields[j])) {
        if (atom_used$origin_fields[j] == "Start" |
            atom_used$origin_fields[j] == "End") {
          atom_template[i, atom_used$atom[j]]  <-
            paste0(origin[i, atom_used$origin_fields[j]], "-00-00")
          
        } else
          
          atom_template[i, atom_used$atom[j]]  <-
            origin[i, atom_used$origin_fields[j]]
        
      } else if (grepl('=', atom_used$origin_fields[j])) {
        atom_template[i, atom_used$atom[j]] <-
          gsub("^\\[=(.*)]$", "\\1", atom_used$origin_fields[j])
        
      } else if (atom_used$atom[j] == "levelOfDescription" &
                 inst == "SFU Archives") {
        if(is.na(origin$Sub[i]) & is.na(origin$SubSub[i])){
          s <- dplyr::select(origin, Fonds:Item, -Sub, -SubSub)
          max_na <- names(s)[max(which(is.na(s[i,])))-1]
          atom_template[i, "levelOfDescription"] <-
            ifelse(!is.na(origin$Item[i]), "Item", max_na)
          
        } else if (is.na(origin$SubSub[i])) {
          atom_template[i, "levelOfDescription"] <- ifelse(!is.na(origin$Item[i]), "Item", 
                                                               ifelse(!is.na(origin$File[i]), "File", "Subseries"))
        } else
          atom_template[i, "levelOfDescription"] <- ifelse(!is.na(origin$Item[i]), "Item", 
                                                        ifelse(!is.na(origin$File[i]), "File", "Sub-subseries"))

      } else if (atom_used$atom[j] == "qubitParentSlug" &
                 inst == "SFU Archives") {
        atom_template$qubitParentSlug[i] <-
          gsub("(f-\\d+-\\d+-\\d+)-\\d+-\\d",
               "\\1",
               origin$Ref_code[i],
               ignore.case = T)
        
      } else
        next
    }
  }
  
  atom_template
  
}
