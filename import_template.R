# Function takes original description csv and the field mapping csv as parameters
# returns data in atom template form
transform_template <- function(origin, map, inst) {
  # Name formatting
  names(map) <- c("atom", "origin_fields")
  names(origin) <-
    gsub("^\\.\\.", "", names(origin)) # this error occurs from UTF-8 BOM on ms apps
  
  # read.csv() will add an X to col names starting with non-letter/number or non-dot chars. 
  # Change map to reflect this.
  if (inst == "Other") {
    map$origin_fields <- ifelse(
      !grepl("^[[:alpha:]]|^\\d|^\\.|^\\[", map$origin_fields) & !is.na(map$origin_fields),
      paste0("X", map$origin_fields),
           map$origin_fields)
  }
  
  # SFU-specific formatting
  if (inst == "SFU Archives") {
    names(origin)[grep("fonds", names(origin), ignore.case = T)] <-
      "Fonds"
    names(origin) <- gsub('\\.', '_', names(origin))
    origin <- subset(origin, !is.na(origin$Fonds))
    map$origin_fields <- ifelse(
      !grepl("^\\[", map$origin_fields),
      gsub('\\s', '_', map$origin_fields),
      map$origin_fields
    )
  }
  
  # Create empty df to hold atom template data
  atom_template <-
    as.data.frame(matrix(ncol = length(map$atom), nrow = nrow(origin)))
  names(atom_template) <- as.character(map$atom)
  atom_used <- subset(map, !is.na(map$origin_fields))
  
  #Make sure all expected columns are in the original data
  atom_used <-
    subset(
      atom_used,
      atom_used$origin_fields %in% names(origin) |
        grepl("^\\[", atom_used$origin_fields)
    )
  
  for (i in 1:nrow(origin)) {
    for (j in 1:nrow(atom_used)) {
      if (atom_used$origin_fields[j] == atom_used$atom[j]) {
        # if the field in atom has the same name as the field in original
        atom_template[i, atom_used$atom[j]] <-
          origin[i, atom_used$atom[j]]
        
      } else if (!grepl("^\\[", atom_used$origin_fields[j])) {
        # differently named fields with particular requirements
        # if start or end dates are only a year, add -00-00 to them.
        if ((atom_used$origin_fields[j] == "Start" |
            atom_used$origin_fields[j] == "End") & grepl("^[[:digit:]]{4}$", origin[i, atom_used$origin_fields[j]])) {
          atom_template[i, atom_used$atom[j]]  <-
            paste0(origin[i, atom_used$origin_fields[j]], "-00-00")
          
        } else if (atom_used$atom[j] == "physicalObjectType" &
                    inst == "SFU Archives") {
          atom_template[i, atom_used$atom[j]] <- ifelse(is.na(origin$Container_type[i]) & !is.na(origin$Container[i]),
                                                              "Archival box - standard", origin[i, atom_used$origin_fields[j]])
          
        } else if (atom_used$atom[j] == "physicalObjectName" &
                   inst == "SFU Archives") {
          # If container field is NA or anything other than a single number, don't add fonds number
          atom_template[i, atom_used$atom[j]] <-
            ifelse(is.na(origin$Container[i]) | grepl("[[:alpha:]]|[[:punct:]]", origin$Container[i]),
                   origin$Container[i],
                   paste(origin[i, "Fonds"],
                         origin[i, atom_used$origin_fields[j]], sep = "-"))
          
        } else
          # For differently named fields (between original and atom) with no special requirements
          atom_template[i, atom_used$atom[j]]  <-
            origin[i, atom_used$origin_fields[j]]
        
      } else if (atom_used$atom[j] == "levelOfDescription" &
                 inst == "SFU Archives") {
        # For SFU ARM - description level is derived from other columns
        # If there are no subseries or sub-subseries: select only the fonds, series, file, item columns
        # level of description is the max column with an identifier
        if (is.na(origin$Sub[i]) & is.na(origin$SubSub[i])) {
          s <- dplyr::select(origin, Fonds:Item, -Sub, -SubSub)
          max_na <- names(s)[max(which(is.na(s[i,]))) - 1]
          atom_template[i, "levelOfDescription"] <-
            ifelse(!is.na(origin$Item[i]), "Item", max_na)
        
        } else if (is.na(origin$SubSub[i])) {
          atom_template[i, "levelOfDescription"] <-
            ifelse(!is.na(origin$Item[i]),
                   "Item",
                   ifelse(!is.na(origin$File[i]), "File", "Subseries"))
        } else
          atom_template[i, "levelOfDescription"] <-
            ifelse(!is.na(origin$Item[i]),
                   "Item",
                   ifelse(!is.na(origin$File[i]), "File", "Sub-subseries"))
        
      } else if (atom_used$atom[j] == "qubitParentSlug" &
                 inst == "SFU Archives") {
        lm <- tolower(gsub(
          "(F(-\\d+)+)-\\d+$",
          "\\1",
          origin$Ref_code[i],
          ignore.case = T
        ))
        if (endsWith(lm, "-0-0")) {
          atom_template$qubitParentSlug[i] <- gsub("-0-0$", "", lm)
        } else if (endsWith(lm, "-0")) {
          atom_template$qubitParentSlug[i] <- gsub("-0$", "", lm)
        } else
          atom_template$qubitParentSlug[i] <- lm
        
      } else if (grepl('=', atom_used$origin_fields[j])) {
        # For exact text fields (all rows have the same value)
        atom_template[i, atom_used$atom[j]] <-
          gsub("^\\[=(.*)]$", "\\1", atom_used$origin_fields[j])
        
      } else
        next
    }
  }
  
  if (inst == "SFU Archives"|inst == "SFU Special Collections") {
    for (k in 1:nrow(atom_template)) {
      if (is.na(atom_template$physicalObjectName[k])) {
        atom_template$physicalObjectLocation[k] <- NA
        atom_template$physicalObjectType[k] <- NA
      }
      if (is.na(atom_template$eventDates[k])) {
        atom_template$eventTypes[k] <- NA
        atom_template$eventStartDates[k] <- NA
        atom_template$eventEndDates[k] <- NA
      }
    }
  }
  
  atom_template
  
}
