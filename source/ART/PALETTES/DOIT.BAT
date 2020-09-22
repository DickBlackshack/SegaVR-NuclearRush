@echo off
echo static const WORD All_Palettes[] = { >lala.doc
getpal midwest\daypal.lbm >>lala.doc
getpal frozen\daypal.lbm >>lala.doc
getpal desert\daypal.lbm >>lala.doc
getpal forest\daypal.lbm >>lala.doc
getpal flatcity\daypal.lbm >>lala.doc
getpal frozen\daypal.lbm >>lala.doc
getpal vegas\daypal.lbm >>lala.doc
getpal ocean\daypal.lbm >>lala.doc
getpal palette2\daypal.lbm >>lala.doc
getpal palette3\daypal.lbm >>lala.doc

getpal midwest\duskpal.lbm >>lala.doc
getpal frozen\duskpal.lbm >>lala.doc
getpal desert\duskpal.lbm >>lala.doc
getpal forest\duskpal.lbm >>lala.doc
getpal flatcity\duskpal.lbm >>lala.doc
getpal frozen\duskpal.lbm >>lala.doc
getpal vegas\duskpal.lbm >>lala.doc
getpal ocean\duskpal.lbm >>lala.doc
getpal palette2\duskpal.lbm >>lala.doc
getpal palette3\duskpal.lbm >>lala.doc

getpal midwest\nitepal.lbm >>lala.doc
getpal frozen\nitepal.lbm >>lala.doc
getpal desert\nitepal.lbm >>lala.doc
getpal forest\nitepal.lbm >>lala.doc
getpal flatcity\nitepal.lbm >>lala.doc
getpal frozen\nitepal.lbm >>lala.doc
getpal vegas\nitepal.lbm >>lala.doc
getpal ocean\nitepal.lbm >>lala.doc
getpal palette2\nitepal.lbm >>lala.doc
getpal palette3\nitepal.lbm >>lala.doc

getpal midwest\nitepal.lbm >>lala.doc
getpal frozen\nitepal.lbm >>lala.doc
getpal desert\nitepal.lbm >>lala.doc
getpal forest\nitepal.lbm >>lala.doc
getpal flatcity\nitepal.lbm >>lala.doc
getpal frozen\nitepal.lbm >>lala.doc
getpal vegas\nitepal.lbm >>lala.doc
getpal ocean\nitepal.lbm >>lala.doc
getpal palette2\infrapal.lbm >>lala.doc
getpal palette3\infrapal.lbm >>lala.doc

echo }; >>lala.doc

echo static const WORD Drone_Palettes[] = { >>lala.doc
getpal drones\golddron\daypal.lbm >>lala.doc
getpal drones\golddron\duskpal.lbm >>lala.doc
getpal drones\golddron\nitepal.lbm >>lala.doc
getpal drones\golddron\infrapal.lbm >>lala.doc

getpal drones\purpdron\daypal.lbm >>lala.doc
getpal drones\purpdron\duskpal.lbm >>lala.doc
getpal drones\purpdron\nitepal.lbm >>lala.doc
getpal drones\purpdron\infrapal.lbm >>lala.doc

getpal drones\bluedron\daypal.lbm >>lala.doc
getpal drones\bluedron\duskpal.lbm >>lala.doc
getpal drones\bluedron\nitepal.lbm >>lala.doc
getpal drones\bluedron\infrapal.lbm >>lala.doc

getpal drones\greydron\daypal.lbm >>lala.doc
getpal drones\greydron\duskpal.lbm >>lala.doc
getpal drones\greydron\nitepal.lbm >>lala.doc
getpal drones\greydron\infrapal.lbm >>lala.doc

getpal drones\sanddron\daypal.lbm >>lala.doc
getpal drones\sanddron\duskpal.lbm >>lala.doc
getpal drones\sanddron\nitepal.lbm >>lala.doc
getpal drones\sanddron\infrapal.lbm >>lala.doc

getpal drones\golddron\daypal.lbm >>lala.doc
getpal drones\golddron\duskpal.lbm >>lala.doc
getpal drones\golddron\nitepal.lbm >>lala.doc
getpal drones\golddron\infrapal.lbm >>lala.doc

getpal drones\purpdron\daypal.lbm >>lala.doc
getpal drones\purpdron\duskpal.lbm >>lala.doc
getpal drones\purpdron\nitepal.lbm >>lala.doc
getpal drones\purpdron\infrapal.lbm >>lala.doc

getpal drones\greydron\daypal.lbm >>lala.doc
getpal drones\greydron\duskpal.lbm >>lala.doc
getpal drones\greydron\nitepal.lbm >>lala.doc
getpal drones\greydron\infrapal.lbm >>lala.doc

echo }; >>lala.doc

copy lala.doc ..\..\palettes.c68

