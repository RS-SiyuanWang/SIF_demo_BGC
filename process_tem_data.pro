PRO process_tem_data
  file_dir = 'I:\RS_DATA\DroughtMonitor\spei\data\txt_change\'
  out_dir = 'I:\RS_DATA\DroughtMonitor\spei\results\temp\'
  txt_file = FILE_SEARCH(file_dir,'*change.txt',count = count)



;对经纬度的处理

  lat_path = 'I:\RS_DATA\DroughtMonitor\spei\infochange.txt'
  OPENR,lun,lat_path,/get_lun
  lat_lines = FILE_LINES(lat_path)
  lat_data = STRARR(lat_lines)
  READF,lun,lat_data


  lat_arr = STRARR(1,lat_lines)
  ID_arr = STRARR(1,lat_lines)

  FOR ii=0L,lat_lines-1 DO BEGIN
    slat_data=strsplit(lat_data[ii],' ',/extract)
    ID_arr[ii]=slat_data[0]
    lat_arr[ii]=slat_data[1]
    
  ENDFOR
  FREE_LUN,lun


  
  ;FOR i=0L,1 DO BEGIN
  FOR i=0L,count-1 DO BEGIN
    ascii_file = txt_file[i]
    
    openr,lun,ascii_file,/get_lun
    nl = file_lines(ascii_file)
   
    data = strarr(nl)
    readf,lun,data
   
    ;read different data
    station_arr = STRARR(nl)
    per_arr = STRARR(nl)
    tem_arr = STRARR(nl)
    year_arr = STRARR(nl)
    month_arr = STRARR(nl)
    for j=0,nl-1 do begin
      sdata=strsplit(data[j],' ',/extract)
      tem_arr[j]=sdata[4]
      per_arr[j]=sdata[9]
      year_arr[j]=sdata[1]
      station_arr[j]=sdata[0]
      month_arr[j]=sdata[2]  
    endfor
   
    ;对坏值进行处理
    for k=0L,nl-1 do begin
      if per_arr[k] eq '999999' then begin
        per_arr[k] ='0'
      endif
      IF per_arr[k] EQ '999998' THEN BEGIN
        per_arr[k] ='0'
      ENDIF
      IF per_arr[k] EQ '999990' THEN BEGIN
        per_arr[k] ='0.01'
      ENDIF
    endfor
    ;完成
    ;统计一下一共有多少年的数据
    year_amount= long((year_arr)[nl-1])-long((year_arr)[0])

    ;按照月份累加降水数据
    per_arr_new = strarr(1)
    for m=long((year_arr)[0]),long((year_arr)[nl-1]) do begin
      per_year_new =strarr(12);per_year_new是记录一年12各月降水数据的累计值
      ;处理每一年的数据
      for n=1L,12 do begin
        ;处理每个月的数据
        per_new = float(0)
        ;对每一行进行判断处理
        for x=0L,nl-1 do begin
           if long((year_arr)[x]) eq m and long((month_arr[x])) eq n then begin
           per_new += float(per_arr[x])
           endif
        endfor
        per_year_new[n-1]=string(per_new)
      endfor
      per_arr_new = [per_arr_new,per_year_new]
    endfor
    per_lines = (size(per_arr_new))[1]
    ;完成
    
    
    ;按照月份累加气温数据
    tem_arr_new = strarr(1)
    FOR m=LONG((year_arr)[0]),LONG((year_arr)[nl-1]) DO BEGIN
      tem_year_new =STRARR(12);per_year_new是记录一年12各月降水数据的累计值
      ;处理每一年的数据
      FOR n=1L,12 DO BEGIN
        ;处理每个月的数据
        tem_new = FLOAT(0)
        tem_count_arr = strarr(1)
        ;对每一行进行判断处理
        FOR x=0L,nl-1 DO BEGIN
          IF LONG((year_arr)[x]) EQ m AND LONG((month_arr[x])) EQ n THEN BEGIN
            tem_new += FLOAT(tem_arr[x])
            tem_count_arr = [tem_count_arr,month_arr[x]]
          ENDIF
        ENDFOR
        tem_count = ((size(tem_count_arr))[1])-1
        tem_new = float(tem_new/tem_count)
        tem_year_new[n-1]=STRING(tem_new)
        ;print,tem_count
      ENDFOR
      tem_arr_new = [tem_arr_new,tem_year_new]
    ENDFOR
    ;完成
    
    
    station_ID = (station_arr)[0]
    year = (year_arr)[0]
    month = (month_arr)[0]
   
   
    ;把经纬度从秒转换为小数
    FOR jj=0L,lat_lines-1 DO BEGIN
    IF ID_arr[jj] EQ station_ID THEN BEGIN
      lat_info = lat_arr[jj]
    ENDIF
    ENDFOR
    lat_int = STRMID(lat_info,0,2)
    lat_dec= STRMID(lat_info,2,4)
    lat_int = DOUBLE(lat_int)
    lat_dec = DOUBLE(lat_dec)
    lat_dec =(lat_dec)/60
    lat_info = lat_int+lat_dec
    lat_info = STRING(lat_info)
    lat_info = STRCOMPRESS(lat_info,/REMOVE_ALL)
    FREE_LUN,lun
    
    ;get the out_name
    basename = FILE_BASENAME(txt_file[i],'.TXT')
    out_name = out_dir + basename + '_result.txt'
    month_string='12'
    
    ;写文件
    OPENW,lun,out_name,/get_lun
    PRINTF,lun,station_ID
    PRINTF,lun,lat_info
    PRINTF,lun,year+';'+month
    PRINTF,lun,month_string
    FOR jj=1,per_lines-1 DO BEGIN
      per_tem_line = string(per_arr_new[jj]+';'+tem_arr_new[jj])
      per_tem_line = STRCOMPRESS(per_tem_line,/REMOVE_ALL)
      PRINTF,lun,per_tem_line
    ENDFOR
    FREE_LUN,lun
    
    file_number = i+1
    file_left = STRING(FLOAT(count - file_number))
    print,' THERE ARE '+STRING(year_amount)+' YEARS DATA IN ' + basename
    print,'Processing .....'     and   +file_left+ ' left'
    
  ENDFOR
  print,'ALL DONE..'
  
  
END