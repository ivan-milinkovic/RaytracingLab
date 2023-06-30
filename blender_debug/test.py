file = open("/Users/ivan/labs/RaytracingLab/blender_debug/lines.txt", "r")

def parseVecStr(vecStr):
    coordStr = vecStr.split(",")
    return [float(coordStr[0]), float(coordStr[1]), float(coordStr[2])]
    

for line in file:
    vs = line.split(";")
    pstr = vs[0]
    nstr = vs[1]

    pv = parseVecStr(pstr)
    nv = parseVecStr(nstr)

    print(pv)
    print(nv)

file.close()
