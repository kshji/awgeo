# AwGeo - Apuvälineitä paikkatiedon käsittelyyn ja kartoitukseen 

<img src="../../blob/master/examples/result1.png" width="50%" height="50%">

Olen jokseenkin kokenut suunnistuksen toimija. Nuorempana kilpailijana ihan tosissaan treenaten ja kilpaillen.
Sittemmin yhtenä vetäjistä Kalevan Rastin huippusuunnistuksessa (199?-2009). Ocadin kanssa vuodesta 1993 alkaen.

Kaikenlaisia suunnistukseen liittyviä palveluja tullut rakennettua vuodesta 1983. Nettipalveluina 1999 alkaen.

Suomessa olemme siinä suhteessa "onnekkaita", että Maanmittauslaitoksen aineistosta iso osa on avoimesti saatavissa.
Jotain vastinetta maksetuille veroilla ilman, että tarvitsee erikseen maksaa uudelleen.
Mm. Merenkulkulaitos ei ole oivaltanut saman idean hyötyä kansantaloudelle ja itselleen. Maanmittauslaitos on
itsekin saanut hyötyä syntyneistä ohjemistoista ja palveluista. Mm. Pullautin, MapAnt jne. Ilman
avointa dataa ei olisi syntynyt erilaisia palveluja perustuen MML:n avoimeen dataan.

[MML Avoin data](https://asiointi.maanmittauslaitos.fi/karttapaikka/tiedostopalvelu?lang=fi).
[Lisenssi CC 4.0](https://creativecommons.org/licenses/by/4.0/deed.fi), 
[Maanmittauslaitos](https://www.maanmittauslaitos.fi/)

  * [Awot](https://awot.fi), yritykseni
  * [Suunnistus.info](https://suunnistus.info), suunnistussivuni
  * [Kalevan Rasti](https://kalevanrasti.fi), seurani 1983 alkaen
  * [Github kshji](https://github.com/kshji), github arkistoni, kaikenlaista koodin pätkää

## Käyttämäni työkalut
Oheisissa ratkaisuissa on käyttänyt pääasiassa ohjelmistoja: Lastools, PDAL and GDAL.
Ja tietysti Jarkko Ryypön tuotteistamaa loistavaa Pullautinta.
    
  * [PROJ](https://proj.org/)
  * [GDAL](https://gdal.org/)
  * [PDAL](https://pdal.io/)
  * [Lastools](https://lastools.github.io/)
  * [Karttapullautin arkisto](https://www.routegadget.net/karttapullautin/), Pullautetaan kartta MML aineistosta. Kiitos Jarkko Ryyppö.
  * [Karttapullautin Github](https://github.com/rphlo/karttapullautin), sama ***pullautin*** ohjelma, mutta uudelleen kirjoitettuna käyttäen Rust-ohjelmointikieltä. Käytä tätä versiota, on todella nopea. Vanha 2 tuntia onkin 2 minuuttia.
  * [Karttapullautin Perl](https://github.com/linville/kartta-pack), alkuperäinen perl version, edelleen päivittyy  - osa optioista toimii edelleen vain tässä versiossa
  * [LasPy](https://laspy.readthedocs.io/), [Python kirjasto](https://pypi.org/project/laspy/) laserdatan LAS/LAZ murskaukseen ja laskentaan, [Github](https://github.com/laspy/laspy)
  * [OCAD](https://ocad.com), Ocad kartantekijöille, kaupallinen
  * [Omapper](https://www.openorienteering.org/apps/mapper/), Omapper on ilmainen avoimen koodin cad kartantekijöille
  * [PurplePen](https://purple-pen.org), ilmainen avoimen koodin ratojen suunnittelu

Em. ohjelmien lisenssit löytyvät ko. ohjelmien sivuilta.

### Online työkaluni
  * [Shp2Dxf](https://awot.fi/sf/ocad/shp2dxf) online työkaluni tuottaa DXF-tiedostoja MML:N SHP-tiedostoista 
käytettäväksi vaikka [Ocad](https://ocad.com)-ohjelmassa
  * [Ocad suunnan korjaus KOK: neulaluvun korjaus + nak](https://awot.fi/sf/ocad/ocaddec?lang=fin)

### Laser materiaalin työkaluja
  * [GeoTIFF.io](https://app.geotiff.io/) GeoTiff esitys, 
  * [Pullautuskartta](https://pullautuskartta.fi/)
  * [Kapsi.fi](https://kartat.kapsi.fi/), MML:n datojen jakelukanava
  * [MapAnt FI](https://mapant.fi/)
  * [CloudCompare](https://github.com/cloudcompare/cloudcompare), CloudCompare on ilmainen 3D paikkatiedon käsittely 
ja esitystyökalu. CCViewer on pelkkä esitysversio.
  * [QGIS](https://www.qgis.org/), Geodatan esitys ja muokkaustyökalu, Open Source, vajaa 2 GT:n järkälä. QGIS:llä 
neuvotaan tekemään paikkatiedolle sitä ja tätä ...
  * [Courses: Point cloud processing with QGIS and PDAL wrench](https://courses.gisopencourseware.org/course/view.php?id=63)
  * [Courses: Programming for Geospatial Hydrological Applications](https://courses.gisopencourseware.org/course/view.php?id=2)
  * [Geospatial School](https://geospatialschool.com/)
  * [Awesome-Geospatial](https://github.com/sacridini/Awesome-Geospatial), list of geotools
  * [Proj Widard](https://projectionwizard.org/)
  * [World Magnetic Model (WMM)](https://www.ncei.noaa.gov/products/world-magnetic-model)

### Muita mielenkiintoisia työkaluja
  * [Virtual DOS](https://copy.sh/v86/?profile=msdos), [Github](https://github.com/copy/v86), myös Linux, Windows98, ... aikamoista.

### Paikkatietotyökalujen (Geo) asennus
Tämä esimerkkiohjeistus on tehty käyttäen Ubuntu, Debian ja WSL2 Ubuntu Linux:ja. WSL2 on virtuaaliympäristö
Windowsiin, jossa
voi suorittaa esim. eri Linux:ja ns. natiivisti.  
Ei tarvitse välttämättä erillistä Linux purkkia ajaaksesi Linux ympäristöä.

Kunkin ohjelman sivustot ohjeistavat kuinka saa asennettua Windowsiin, Applen OS/X:ään jne.

Kaikkinensa koko paketin asennus voi olla aika haastavaa. Eri paketit olettavat kirjastoilta jotain versiotasoa ja
se ei taas välttämättä onnistu helposti omassa ympäristössäsi. Kuten oheisista ohjeista voi havaita, voi joutua
jumppaamaan, jotta eri paikkatieto-ohjelmistot saa toimimaan samassa ympäristössä.

#### Ubuntu, Debian, WSL2 Ubuntu, ...

```sh
#sudo apt-get install proj-bin libproj-dev
sudo apt-get install python3-dev python3.8-dev python3-pip
# päivitä PIP
pip3 install --upgrade pip

# GDAL install include PROJ
# Official stable UbuntuGIS packages.
sudo add-apt-repository ppa:ubuntugis/ppa
sudo apt-get update
sudo apt-get install gdal-bin libgdal-dev 
#       Check:
ogrinfo --version

sudo apt-get install python3-gdal python3-numpy

# If using perl and need GDAL, then
sudo apt-get install libgd-gd2-perl
# PDAL
sudo apt-get install -y pdal libpdal-plugins
```

If you get error ***free(): invalid pointer*** using cmds:
```sh
ogrinfo --version
gdalinfo --version
pdal --version
```
libproj version kanssa oli eniten haasteita saada toimimaan.
Tuorein versio piti tehdä softalinkkejä vanhemmille versioille. Sitten pääsi eri virheilmoituksista eroon.

[Read solutions](https://stackoverflow.com/questions/72345761/gdal-ogr2ogr-ogrinfo-produces-an-invalid-pointer-error-each-time-i-run-it).


#### Pip for python
```sh
# User env
#       - look version using: ogrinfo --version
#       - in this example version is 3.3.2
       pip install GDAL==3.3.2
       pip install pygdal=="3.3.2.*"
       pip install laspy[laszip]
       pip install scipy numpy
       pip install lasio


```


## Awot sh-scripts use various software, including proj, gdal, pdal, lastools, ...
Kaikki esimerkit löytyy kansiosta ***examples***.

### AWGEO ympäristön asetukset
Kun olet kopsannut tämän ***awgeo*** ympäristön, niin muokkaa ***config/awgeo.ini***, jossa
kerrotaan missä hakemistossa tämä paketti on.

config/awgeo.ini
on rivi, johon kerrotaan tämä asennushakemisto.
```
AWGEO=/home/user/awgeo
```


### raw2xy.sh - Tehdään XY viiva Ocadin viivan tiedoista. 
 * piirrä viivalla alue Ocad:ssä
 * Katso alueen ominaisuudet, valikon nappula ***i***  
 * dialogi *Kohteen tiedot*
 * klikkaa kopio nappulaa dialogin oikeassa alanurkassa, kopioi tiedot leikepöydälle
 * tallenna ko. tiedot tiedostoon esim. area.raw
 * katso examples kansiosta malli area.raw, millaisen tiedoston tulisi olla

Konvertoi ko. raakadata xy formaattiin:
```sh
$AWGEO/raw2xy.sh -i area.raw -o area.txt

```

### xy2wkt.sh - Tehdään WKT alue x,y alueen tekstitiedostosta 

Konvertoidaan x,y alue tekstitiedosto WKT alue formaattiin.

```sh
cd examples
cat area.txt
632162.5 6954655.8
632176.7 6954656.9
632200.1 6954651.5
632162.5 6954655.8

$AWGEO/xy2wkt.sh -i area.txt -o area.wkt
# or using pipe
cat area.txt | $AWGEO/xy2wkt.sh > area.wkt
```

### lazcrop.sh - Crop polygon area from LAZ file
### lazcrop.sh - Alueen rajaus LAZ tiedostosta

Lastools ***lasclip*** tai oheisella PDAL scriptillä saat rajattua halutun alueen LAZ-tiedostosta.
***lazcrop.sh*** tarvitsee alueen WKT-tiedostona. Katso edellä ***xy2wkt.sh*** kuinka x,y alue tekstitiedosto muutetaan
wkt formaattiin.

```sh
# using lastools
lasclip64 -i example.laz -o areax.las -poly area.txt
# using lazcrop.sh
$AWGEO/lazcrop.sh -i example.laz -p area.wkt -o areay.las

```

### laz2tif.sh - Tehdään GeoTIFF kuvatiedosto LAZ-tiedostosta
```sh
laz2tif.sh -i input.laz -o result.tif [ -d 0|1 ]
   -i input laz file name
   -o result tif file
   -d 0|1 , default 0 - debug output
   -v       version
   -h       this help
```
Ohessa esimerkki kuinka examples/example.laz tiedostosta tehdään GeoTIFF kuvatiedosto.
```sh
cd examples
$AWGEO/laz2tif.sh -i example.laz -o example1.tif
```
Lopputulos example1.tif

### hillshade.sh - Tehdään rinneverjokuva laserdatasta

<img src="../../blob/master/examples/example1.png" width="30%" height="30%">

```sh
hillshade.sh -i input.laz -o resultname [ -z NUMBER ] [ -g 0|1 ] [ -d 0|1 ]
   -i input laz file name
   -o resultname, result file is resultname.tif !!!
   -g 0|1 , default 1, using ground filter or not
   -z NUMBER  , default is 3
   -d 0|1 , default 0 - debug output
   -v 	     version
   -h       this help
```
Esimerkkinä tehdään example.laz tiedostosta rinnevarjokuva:
```sh
cd examples
$AWGEO/hillshade.sh -i example.laz -o example1
```
Tulostiedosto example1.tif

Muutetaan Tiff tiedosto PNG-tiedostoksi:
```sh
gdal_translate -of PNG example1.tif example1.png
```

  * oletusarvot, katso scriptin hillshade.sh funktioista ***json ja set_def***

### lidar_volume.py - Laske tilavuus laserdatasta

<img src="../../blob/master/examples/hill.png" width="30%" height="30%">
Oheinen kukkula, lasketaan sen tilavuus.

KO. algoritmillä voidaan laseka laserdatasta tilavuus halutun korkeustason yläpuolelta.

***lidar_volume.py*** 

Ohessa esimerkki kuinka rajataan haluttu alue laserdatasta ja lasketaan rajatun alueen tilavuus korkeustason
112 yläpuolelta.
```sh
cd examples
# alue area.txt erotetaan example.laz tiedostosta tiedostoon areax.las
lasclip64 -i example.laz -o areax.las -poly area.txt  -keep_class 2
# voidaan myös lasclip ohjelmallakin jo rajata korkeustaso lähdedatasta. Toki lidar_volume.py hyväksyy
# attribuuttina korkeustason (z)
lasclip64 -i example.laz -o areax.las -poly area.txt  -keep_class 2  -drop_z_below 112
# tai käytä lazcrop.sh

# tai käytä Pdal komentoa purkaaksesi laz tiedoston las tiedostoksi:
pdal translate example.laz example.las

# katso lazcrop.sh kuinka saadaan rajattu alue kaivettua laz-tiedostosta.

# lasketaan tilavuus las-tiedostosta (pakattu laz purettu)
python3 $AWGEO/lidar_volume.py areax.las 112
112.0 38780.31 m3

```

### GeoTIFF kääntö
[Source](https://gis.stackexchange.com/questions/418517/rotation-of-a-spatial-grid-by-an-angle-around-a-pivot-with-python-gdal-or-raster) for this solution. 
Thanks for [WaterFox](https://gis.stackexchange.com/users/167793/waterfox).

```sh
python3 rotate.angle.py source.tif  kulma rotated.tif
# kulma on +/- asteita
```

### Poista geokoordinaatuiosto GeoTIFF tiedostosta, lopputulos pelkkä TIF-kuva
Geodata tarvitaan poistaa GeoTIFF tiedosta, tarvitaan tavalline TIF kuvatiedosto ilman paikkatietoa.

```sh
gdal_translate -of GTiff -co PROFILE=BASELINE input.tif output.tif
# tai
cp geotif.tif output.tif
gdal_edit.py  -unsetgt output.tif
```


### Metsän varjokuva laserdatasta
Tuotetaan varjokuva, joka ilmentää puuston korkeutta ja tiheyttä.
Tästä saa kaivettua mm. ojat, kuviorajat yms. pullauttimen tuloksen kaveriksi.

Tarkemmin käytöstä itse scriptissä.
```sh
forest.sh
```

### Rinnevarjo ja metsävarjokuva laserdatasta

Suoritetaan yhdessä hillshade.sh ja forest.sh

Tarkemmin käytöstä, katso scriptistä.
```sh
forest_hillshade.sh
```

### Karttapullautin massa-ajona

***pullauta.run.sh*** on minun versioni ***pullauta*** massa-ajona isommasta alueesta = paljon LAZ-tiedostoja.

Tämä versio tuottaa myös erilaisia taustakuvia etenkin kartantekijöille enemmän kuin ***pullauta*** tuottaa.

#### asetukset
 * tee hakemistot ***sourcedata*** ja ***pullautettu*** - kaikki muut sallittuja paitsi ajo itse käyttää
sisäisesti input ja output, joten käytä jotain muita hakemistonimiä
 * config/pullauta.ini sisältää joitain muuttujia ($xxx), jotka suorituksen aikana lavennetaan, joten jos ja kun haluat säätää pullauta.ini arvoja, niin muokkaa ko. tiedostoa. Muuttujat ovat osa ko. massa-ajoa, oltava
 * muokkaaa config/awgeo.ini, aseta hakemisto, jossa AwGeo ohjelmat ovat TAI aseta ympäristömuuttuja AWGEO
arvoksi ko. hakemisto

#### config/pullauta.ini
Oltava
```sh
batch=1
processes=4  # montako suorittimen ydintä voidaan rinnakkain käyttää
batchoutfolder=./output  # pullauta ohjelma tuottaa tuloksen tähän kansioon ja tuhoaakin sen - älä käytä output kansiota
lazfolder=./input  # pullauta.run.sh käyttää input kansiota pullautukseen, älä käytä omissa jutuissa - tuhoutuu
```

#### suoritus

Normaali suoritus:
 * laita lähdedata kansioon ***sourcedata***: LAZ + Maastotietokanta SHP pakatut (ZIP)
 * suoritetaan pullauta.run.sh
 * tuottaa oletuksena myös rinnevarjokuvan, metsävarjokuvan ja välikäyrän 1.25/0.625 valinnan mukaan

```sh
pullauta.run.sh -a 11 -i 0.625 --hillshade -z 3 --spikefree  --config $MYHOME/pullauta.ini
# - suuntaviivat kulma 11, välikäyrä 0.625, rinnevarjokuva z=3
# - config template init file: $MYHOME/pullauta.ini , remember have to be dynamic angle set
# or use "full set" using defaults
# tai suorita koko oletuspaketti optiolla --all ja kerrot vain korjauskulma sekä välikäyrä
# lähdedata kansiossa sourcedata, ja lopputulos tulee kansioon pullautettu
pullauta.run.sh --all -a 11 -i 0.625 
# tai kerro mistä löytyy lähdedata ja minne laitetaan lopputulos
pullauta.run.sh --all -a 11 -i 0.625 --in lahde/P5113L --out tulos/P5113L
```

Pelkkä pullautuskartta kulmalla 11:
```sh
pullauta.run.sh -a 11 
```

<img src="../../blob/master/examples/rukko.map.png" width="50%" height="50%"> Valmis kartta

Muutama esimerkki syntyvistä taustakuvista, voi hyödyntää jo ennen maastokäyntejä.

<img src="../../blob/master/examples/rukko.hillshade.2.png" width="50%" height="50%"> 

Varjokuva maaston muoto (DEM)

<img src="../../blob/master/examples/rukko.hillshade.png" width="50%" height="50%"> 

Varjokuva, taustalla käyrät yms.

<img src="../../blob/master/examples/rukko.sf.png" width="50%" height="50%"> 

Pintakuvio, mukana puusto yms. Näkyy hyvin mm. ojat, ajourat, ...

<img src="../../blob/master/examples/rukko.color.fo.2.png" width="50%" height="50%"> 

DSM, mukana vain 1. piste kustakin kohdasta = puuston tiheys ja korkeus

<img src="../../blob/master/examples/rukko.color.fo.png" width="50%" height="50%"> 

DSM, mukana vain 1. piste kustakin kohdasta = puuston tiheys ja korkeus
 * valkoinen - pohja, ei kasvillisuutta
 * keltainen - tosi matala kasvillisuus
 * tumman vihreä, matala kasvillisuus (taimikkokorkeus)
 * vaalean vihreä - keskikorkea puusto, esim. kuusikko hyvin usein jää tähän korkeuteen
 * vaalea oranssi - edellistä korkeampaa, yli 20 metristä.
 * punainen - korkein metsä

<img src="../../blob/master/examples/rukko.vege.png" width="50%" height="50%"> 

Vihreä, Pullauttimen tuottama

<img src="../../blob/master/examples/rukko.tree_height_density.png" width="50%" height="50%"> 

Pelkkä puusto tiheyden ja pituuden mukaisesti, tumman vihreä matalin = taimikko

<img src="../../blob/master/examples/rukko.tree_height_density.middle.png" width="50%" height="50%"> 

Keskimmäinen kasvillisuus - nuori metsä yleensä, suunnistuskartalla ehkä vihreää. Riippuu tiheydestä.

## Tulossa

### Yksi komento - lopputuloksena joukko taustakuvia ja kaikki tarvittavat DXF:t ladattavaksi Ocadiin

<img src="../../blob/master/examples/result1.png" width="30%" height="30%">

Oheinen komento jauhaa kolmisen tuntia Intel i7 prossun tietokoneella käyttäen 4 ydintä, 32 GT RAM, SSD kovalevyllä. 
Lopputuloksena oheinen kaikki tarpeellinen (ja tarpeeton), suunnilleen 4 GT dataa yhdestä maastotietokannan
ruudusta 12x12 km (tile).
```sh
get.area.all.sh  P5313L
```

  * [Katso aluekoodi](https://asiointi.maanmittauslaitos.fi/karttapaikka/tiedostopalvelu/maastotietokanta?lang=fi), 
Maastotietokanta, ESRI shapefile formaatti = näkyy ko. ruutuina Suomi.
  * Hakee MML:n alueen datan, esimerkiksi alue P5313L
  * jotta haku toimii, tarvitset MML:N api-avaimen tai käytä [Kapsi.fi](https://kartat.kapsi.fi/)-palvelinta
saadaksesi ko. materiaalin. Suosittelen: hanki api-avain korvauksetta MML:lta, on varmasti tuorein data tarjolla
  * suorita - lopputulos sisältää kaiken tämän:
    * hakee alueen kaikki ilmakuvat, laserdatan, maastotietokannan datan, tilarajat
    * hakee Metsähallitukselta hakkuuilmoitukset halutun vuoden jälkeen
    * tuottaa maastotiedotokannasta ja hakkuuilmoituksista DXF-tiedostot ladattavaksi esim. Ocadiin
    * suorittaa ***pullauta*** tuottaen myös välikäyrän 0.625 
    * rinnevarjokuva
    * metsävarjokuva
    * FIshp2ISOM2017.crt tiedosto Ocadiä varten, jotta DXF:n tuonti onnistuu ISOM2017II symbolein 
    * valmis OCD-tiedosto suuntaviivoin
	* muutama erikoissymboli, mm. rakennukset eri reunaviiva MML:n luokituksesta riippuen
  * Ocad:ssä tuodaan ko. DXF:t käyttäen ko. CRT-tiedostoa
  * Ocad:ssä taustakuvaksi kaikki em. kuvat
  * Sitten vaan kartoittamaan /suunnistamaan / ...


Avoin data: [paikkatietoaineisto](https://asiointi.maanmittauslaitos.fi/karttapaikka/tiedostopalvelu?lang=fi).
[Lisenssi CC 4.0](https://creativecommons.org/licenses/by/4.0/deed.fi),
datan tuottaja  [Maanmittauslaitos](https://www.maanmittauslaitos.fi/fi)

