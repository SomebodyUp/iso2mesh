#!/bin/sh

#============================================================
#  iso2mesh documentation to wiki convertor
#
#  Author: Qianqian Fang <fangq at nmr.mgh.harvard.edu>
#============================================================

print_help()
{
   awk '/^%/ {dp=1} /-- this function is part of iso2mesh/ {exit} 
        /^function/ {dp=1} /./ {if(dp==1) print;}' $1 \
     | grep -v 'Qianqian' | grep -v 'date:' | grep -v '^%\s*$'| \
     sed -e 's/^%//g' -e 's/^function\(.*$\)/\n==== function\1 ====/g'
}
print_group()
{
   for fun in $@
   do 
      print_help $fun.m
   done
}

func_shortcut="v2m v2s s2m sms"
func_mainfun="vol2mesh vol2surf surf2mesh surf2vol"
func_backend="binsurface cgalv2m cgals2m vol2restrictedtri surf2volz"
func_inquery="finddisconnsurf surfedge volface extractloops meshconn  
                meshcentroid nodevolume elemvolume neighborelem 
		faceneighbors maxsurf flatsegment orderloopedge  
		mesheuler bbxflatsegment"
func_meshfix="meshcheckrepair meshreorient removedupelem 
                removedupnodes removeisolatednode removeisolatedsurf
                surfaceclean getintersecttri delendelem"
func_remesh="meshresample remeshsurf smoothsurf sortmesh"
func_fileio="saveasc savedxf saveinr saveoff savesmf savesurfpoly 
                savevrml readasc readinr readmedit readoff readsmf
	        readtetgen deletemeshfile mcpath mwpath"
func_binimage="bwislands fillholes3d deislands2d deislands3d 
                imedge3d internalpoint smoothbinvol 
		thickenbinvol thinbinvol"
func_plotting="plotmesh plotsurf plottetra qmeshcut"
func_misc="surfdiffuse volmap2mesh isoctavemesh getvarfrom 
		getplanefrom3pt getexeext"

echo === "#" Streamlined mesh generation - shortcuts ===
print_group $func_shortcut

echo === "#" Streamlined mesh generation ===
print_group $func_mainfun

echo === "#" iso2mesh main function backend ===
print_group $func_backend

echo === "#" Mesh decomposition and query ===
print_group $func_inquery

echo === "#" Mesh processing and reparing ===
print_group $func_meshfix

echo === "#" Mesh resampling and optimization ===
print_group $func_remesh

echo === "#" File I/O ===
print_group $func_fileio

echo === "#" Volumetric image pre-processing ===
print_group $func_binimage

echo === "#" Mesh plotting ===
print_group $func_plotting

echo === "#" Miscellaneous functions ===
print_group $func_misc

