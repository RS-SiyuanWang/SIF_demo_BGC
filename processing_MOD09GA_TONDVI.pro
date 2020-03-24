function get_ndvi,nir,r
  mask1 = where((nir+r) ne 0 )
  info = size(nir,/dimens)
  ndvi = fltarr(info)-2
  ndvi[mask1] = 1.0 * ((nir-r)[mask1])/((nir + r)[mask1])

  mask2 = where(ndvi gt -1 and ndvi lt 1.0)
  ndvi1 = fltarr(info)-2
  ndvi1[mask2] = ndvi[mask2]
  return, ndvi1
end

pro processing_MOD09GA_TONDVI
  input_dir = 'E:\wsy\Data\MODIS REFL'
  out_dir = 'E:\wsy\Data\Final_NDVI_badpixel=-2'
  ;-------step1 QC mask--------------------------------------------------
  QC_file = file_search(input_dir,'*QC_500m_1.tif',count = count)
  for i=0,count-1 do begin
    basename = file_basename(QC_file[i])
    print,QC_file[i]
    ptr      = (strsplit(basename,'.',/extract))[0]+'.'+(strsplit(basename,'.',/extract))[1]
    QA_file  = input_dir + '\' + ptr+ '.state_1km_1.tif'
    Nir_file = input_dir + '\' + ptr + '.sur_refl_b02_1.tif'
    R_file   = input_dir + '\' + ptr + '.sur_refl_b01_1.tif'
    nir      = read_tiff(Nir_file,geotiff = geotiff)
    r        = read_tiff(R_file, geotiff=geotiff)
    ndvi     = get_ndvi(nir,r)
    ;==========================================================

    ;==========================================================
    QA_data  = read_tiff(QA_file,geotiff = geotiff)
    QC_data  = read_tiff(QC_file[i],geotiff = geotiff)
    ;processing when ndvi and qa file have different dimensions
    ;    if n_elements(ndvi) ne n_elements(QA_data) then begin
    ;       QA_data = QA_data[*,1:*]
    ;    endif
    ;    if n_elements(ndvi) ne n_elements(QC_data) then begin
    ;      QC_data = QC_data[*,1:*]
    ;    endif

    QC_out = bytarr(32,n_elements(QC_data))
    for bbb=0,31 do QC_out[31-bbb,*]=(QC_data and 2L^bbb)/2L^bbb

    ;band 1 and 2 are of the highest quality
    QC_mask = QC_out[31-2,*] eq 0 and QC_out[31-3,*] eq 0 and QC_out[31-4,*] eq 0 and QC_out[31-5,*] eq 0 $
      and QC_out[31-6,*] eq 0 and QC_out[31-7,*] eq 0 and QC_out[31-8,*] eq 0 and QC_out[31-9,*] eq 0

    QA_out = bytarr(16,n_elements(QA_data))
    for bbb=0,15 do QA_out[15-bbb,*]=(QA_data and 2L^bbb)/2L^bbb

    QA_mask = (QA_out[15,*] eq 0 and QA_out[14,*] eq 0) and QA_out[13,*] eq 0  and (QA_out[12,*] eq 1 $
      and QA_out[11,*] eq 0 and QA_out[10,*] eq 0)

    index = where(QC_mask eq 1 and QA_mask eq 1)
    out_data = fltarr(size(ndvi,/dimension))-2
    out_data(index) = ndvi(index)

    ;validate its effectiveness
    test_index = where(out_data gt -2 and out_data lt -1)
    if (test_index ne -1) then print,QC_file[i] + ' is calculated error!!!!'

    write_tiff,out_dir + '\'+ ptr + '_NDVI.tif', out_data, geotiff = geotiff,/float

  endfor
end
;-------step2 QA mask--------------------------------------------------
;
;-------step3 Caculate NDVI b1 b2--------------------------------------


;   for ii = 120,160 do begin
;      if ii lt 100 then begin
;         day = '0'+strtrim(string(ii),2)
;      endif else begin
;         day = strtrim(string(ii),2)
;      endelse
;
;      print,day
;      file_list = file_search(file_dir,'MOD09GA.A*'+day+'_NDVI.tif',count = count)
;      qa_list = file_search(file_dir,'MOD09GA.A*'+day+'.state_500m_1.tif',count = count)
;
;      for i =0, count - 1 do begin
;         print,file_list[i]
;         print,qa_list[i]
;         name = file_basename(file_list[i])
;         name = name.replace('.tif','_New.tif')
;
;         if file_test(out_dir + name) then continue
;
;         data_ndvi = float(read_tiff(file_list[i],geotiff = geotiff))
;         data_qa = read_tiff(qa_list[i])
;
;         ;processing when ndvi and qa file have different dimensions
;         if n_elements(data_ndvi) ne n_elements(data_qa) then begin
;            data_qa = data_qa[*,1:*]
;         endif
;
;         out=bytarr(16,n_elements(data_qa))
;         for bbb=0,15 do out[15-bbb,*]=(data_qa and 2L^bbb)/2L^bbb
;
;         status = (out[15,*] eq 0 and out[14,*] eq 0) and out[13,*] eq 0  and (out[12,*] eq 1 and out[11,*] eq 0 and out[10,*] eq 0)
;         index = where(status eq 1)
;         result = fltarr(size(data_ndvi,/dimension))
;         result(index) = data_ndvi(index)
;         write_tiff,out_dir + name, result, geotiff = geotiff,/float
;      endfor
;   endfor

