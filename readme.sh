Go to https://ode.rsl.wustl.edu/moon/index.aspx

Select the LRO NAC EDR product and a search area. Get the results, and save them to a text file.

It will have entries like:

LRO,	LROC,	Experiment Data Record Narrow Angle Camera,	EDRNAC,	M107162480LE,	2009-09-09T19:07:35.073,	89.0408,	326.2958,	http://ode.rsl.wustl.edu/moon/productPageAtlas.aspx?product_id=M107162480LE&product_idGeo=16499705,


Do:

link='http://ode.rsl.wustl.edu/moon/productPageAtlas.aspx?product_id=M107162480LE&product_idGeo=16499705'
./fetch_rlo.sh "$link"

# Use the parse_index.pl to parse the search results file.

