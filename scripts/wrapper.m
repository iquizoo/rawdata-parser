dataExtract = readsht('splitalldata.xlsx');
resdata = basicCompute(dataExtract);
mrgdata = mergeData(resdata);
statsPlotBatch(mrgdata)
