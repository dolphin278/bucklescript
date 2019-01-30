(* Copyright (C) 2017 Authors of BuckleScript
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)


type module_system = 
  | NodeJS 
  | Es6
  | Es6_global
  (* affect [.cmj] format*)

type package_info 
  = 
  { 
    module_system : module_system ;
    path :  string 
  }

type t 

val iter : 
  t -> 
  (package_info -> unit) ->
  unit 

val empty : t 
val from_name : string -> t 
val is_empty : t -> bool 
val dump_packages_info : 
  Format.formatter -> t -> unit


(** used by command line option 
  e.g [-bs-package-output commonjs:xx/path]
*)
val add_npm_package_path :   
  t ->
  string -> 
  t  

(** Note here we compare the package info by order
  in theory, we can compare it by set semantics
*)
(* val equal : t -> t -> bool  *)

(**
   generate the mdoule path so that it can be spliced here:
   {[
     var Xx = require("package/path/to/xx.js")
   ]}
   Note that it has to be consistent to how it is generated
*)  
val string_of_module_id :
  Lam_module_ident.t ->
  output_dir:string -> 
  module_system ->
  t ->
  (Lam_module_ident.t ->
   (string * t * Ext_namespace.file_kind) option ) -> 
  string