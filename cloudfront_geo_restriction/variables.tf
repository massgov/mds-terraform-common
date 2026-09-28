variable "enabled" {
  type        = bool
  default     = true
  description = "Enables geo-restrictions. Disabled module still outputs valid values that apply no restrictions."
}

variable "create_country_code_list" {
  type        = bool
  default     = false
  description = "Create new parameter store value of country code list"
}

variable "overwrite_country_code_params" {
  type        = bool
  default     = false
  description = "If parameter store value already exists update with lates country code list from here"
}

variable "country_codes" {
  type        = string
  default     = "AE,AF,AZ,BF,BI,BY,CD,CF,CN,CO,CU,DZ,EC,EG,ER,ET,GN,GT,GW,GY,HK,HN,HT,ID,IL,IN,IQ,IR,JM,KE,KP,LB,LY,MD,ML,MM,MO,MR,MX,NE,NG,NI,PG,PH,PK,RU,SA,SD,SO,SS,SV,SY,SZ,TD,TJ,TM,TN,TR,TT,TZ,UA,UG,VE,YE"
  description = "Comma-separated country codes used to initialize or overwrite the geo-blocking parameter."
}
