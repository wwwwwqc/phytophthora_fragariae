# Import modues

import numpy
import csv

# Import dataset to numpy

Inital_tbl = numpy.loadtxt(fname="Parsed_Polarising_95m_contigs_unmasked.tbl",
                           dtype=object)

# Cut down table to give equal variants

tbl2 = Inital_tbl[Inital_tbl[:, 10] == Inital_tbl[:, 9]]
tbl3 = tbl2[tbl2[:, 10] == tbl2[:, 11]]
tbl4 = tbl3[tbl3[:, 10] == tbl3[:, 12]]
tbl5 = tbl4[tbl4[:, 10] == tbl4[:, 13]]
tbl6 = tbl5[tbl5[:, 10] == tbl5[:, 7]]

# Further cut down for different variants

tbl7 = tbl6[tbl6[:, 8] != tbl6[:, 4]]
tbl8 = tbl7[tbl7[:, 8] != tbl7[:, 5]]
tbl9 = tbl8[tbl8[:, 8] != tbl8[:, 6]]
tbl10 = tbl9[tbl9[:, 8] != tbl9[:, 8]]

# Create and append Header row

header = Inital_tbl[0, :]
CSV = numpy.append(header, tbl10)
CSV = numpy.reshape(CSV, (1, 14))

# Print resulting table to a .csv

with open("UK3_polarisation.csv", "wb") as f:
    writer = csv.writer(f)
    writer.writerows(CSV)
