locals {
  superuser_name = var.superuser_username
  config_file = "/home/${var.superuser_username}/.var/app/io.github.dbchoco.muezzin/config/muezzin/config.json"
}

variable "calc_method" {
  description = "The calculation method for prayer times."
  type        = string
}   
variable "madhab" {
  description = "The madhab for prayer time calculations."
  type        = string
}   
variable "latitude" {
  description = "The latitude for prayer time calculations."
  type        = string
}   
variable "longitude" {
  description = "The longitude for prayer time calculations."
  type        = string
}   
variable "timezone" {
  description = "The timezone for prayer time calculations."
  type        = string
}   
variable "startup_sound" {
  description = "Whether to play a startup sound."
  type        = string
  default     = "true"
}   
variable "fajr_custom" {
  description = "Whether to use a custom Fajr adhan."
  type        = string
  default     = "false"
}   
variable "fajr_url" {
  description = "The URL for the custom Fajr adhan."
  type        = string
}   
variable "dua_enabled" {
  description = "Whether Dua is enabled."
  type        = string
  default     = "false" 
}