. apikey.txt
curl -H "Content-Type: application/json" -X POST "https://avoin-paikkatieto.maanmittauslaitos.fi/ogc/v1/processes/maastokartta_vektori_karttalehti/execution?api-key=$apikey" \
	-d '{"id": "maastokartta_vektori_karttalehti","inputs":{ "fileFormatInput":"ESRI shapefile", "dataSetInput":"maastokartta_vektori_100k", "mapSheetInput":["M53"] }}'
