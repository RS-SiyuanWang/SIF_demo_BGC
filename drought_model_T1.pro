function get_filelist,filename
  n_lines = file_lines(filename)
  file_list =!null
  if n_lines ne 0 then begin
    file_list = strarr(n_lines)
    openr,lun,filename,/get_lun
    readf,lun,file_list
    free_lun,lun
  endif
  return, file_list
end

function get_data_from_filelist,filelist
  data = !null
  origin_size = 0
  current_size = 0
  for i = 0, n_elements(filelist)-1 do begin
    file = filelist[i]
    if file_test(file) eq 0 then continue
    fileExtentStr=strmid(file_basename(file),strpos(file_basename(file),'.',/REVERSE_SEARCH)+1)
    if fileExtentStr ne 'tif' then continue
    if query_tiff(file) then begin
      if i eq 0 then begin
        data = read_tiff(file,geotiff = geotiff,interleave = 2)
        origin_size = size(data,/dimension)
      endif else begin
        temp = read_tiff(file,interleave = 2)
        current_size= size(temp,/dimension)
        if origin_size[0] ne current_size[0] or origin_size[1] ne current_size[1] then continue
        data = [[[data]],[[temp]]]
      endelse
    endif
  endfor
  return,list(data,geotiff)
end


function getvaluebyname,xmlobj,tag
  re = xmlobj.GetElementsByTagName(tag)
  if n_elements(re) ge 1 then begin
    node = re.item(0)
    child = node.getfirstchild()
    if child ne !null then begin
      return, child.getnodevalue()
    endif else begin
      return, -99
    endelse

  endif else begin
    return,-99
  endelse

end

function Et0_function,input_file_Tmax,input_file_Tmin,input_file_LN,DOY
  data_Tmax1 = read_tiff(input_file_Tmax,geotiff = geotiff_Tmax,interleave = 2)
  data_Tmin1 = read_tiff(input_file_Tmin,interleave = 2)
  data_LN = read_tiff(input_file_LN,interleave = 2)

  dim = data_Tmax1.dim
  NCOLUMNS = dim[0]
  NROWS = dim[1]
  data = FLTARR(NCOLUMNS, NROWS, 3)
  Et0 = FLTARR(NCOLUMNS, NROWS)
  data[*,*,0] = data_Tmax1
  data[*,*,1] = data_Tmin1
  data[*,*,2] = data_LN
  C = 0.0008
  E = 0.74
  Toff=37.9
  j = DOY
  PI = 3.1415926
  z = 0.409 * sin(2 * PI * j / 365 - 1.39)
  DR = 1 + 0.033 * cos(2 * PI * j / 365)
  for r = 0,NROWS-1 do begin
    for n = 0,NCOLUMNS-1 do begin
      LN = data[n,r,2]
      RAD = LN * PI / 180
      WS = acos(-tan(RAD) * tan(z))
      RA = 24 * 60 / PI * 0.082 * DR * (WS * sin(RAD) * sin(z) + cos(RAD) * cos(z) * sin(WS))

      Et0[n,r] = C/2.45* RA *((data[n,r,0]-data[n,r,1])^E)*((data[n,r,0]+data[n,r,1])/2+Toff)
    endfor
  endfor
  return,Et0
end

function Kc_function,DOY,year,month,day,input_file_KcProvinceID
  DOY_str = strtrim(string(DOY),1)
  year_str = strtrim(string(year),1)
  Data_KcProvinceID = read_tiff(input_file_KcProvinceID,geotiff = geotiff_Kc)
  Hebei_index = where(Data_KcProvinceID eq 1)
  Beijing_index = where(Data_KcProvinceID eq 2)
  Tianjin_index = where(Data_KcProvinceID eq 3)
  Shandong_index = where(Data_KcProvinceID eq 4)
  Henan_index = where(Data_KcProvinceID eq 5)
  Jiangsu_index = where(Data_KcProvinceID eq 6)
  Anhui_index = where(Data_KcProvinceID eq 7)
  Nodata_index = where(Data_KcProvinceID eq 0)
  size_Kc = size(Data_KcProvinceID,/dim)
  Kc = FLTARR(size_Kc)
  Kc(Nodata_index) = -9999.0
  case 1 of
    DOY Gt 0 and DOY Le 31:begin   ;一月
      Kc(Hebei_index)= 0.33
      Kc(Beijing_index)= 0.33
      Kc(Tianjin_index)= 0.33
      Kc(Shandong_index)= 0.64
      Kc(Henan_index)= 0.31
      Kc(Jiangsu_index)= 0.82
      Kc(Anhui_index)= 1.13
    end
    DOY Gt 31 and DOY Le 60:begin;二月
      Kc(Hebei_index)= 0.24
      Kc(Beijing_index)= 0.24
      Kc(Tianjin_index)= 0.24
      Kc(Shandong_index)= 0.64
      Kc(Henan_index)= 0.50
      Kc(Jiangsu_index)= 0.91
      Kc(Anhui_index)= 1.14
    end
    DOY Gt 60 and DOY Le 91:begin;三月
      Kc(Hebei_index)= 0.42
      Kc(Beijing_index)= 0.42
      Kc(Tianjin_index)= 0.42
      Kc(Shandong_index)= 0.90
      Kc(Henan_index)= 0.91
      Kc(Jiangsu_index)= 0.86
      Kc(Anhui_index)= 1.07
    end
    DOY Gt 91 and DOY Le 121:begin;四月
      Kc(Hebei_index)= 1.14
      Kc(Beijing_index)= 1.14
      Kc(Tianjin_index)= 1.14
      Kc(Shandong_index)=1.22
      Kc(Henan_index)=1.40
      Kc(Jiangsu_index)=1.77
      Kc(Anhui_index)=1.16
    end
    DOY Gt 121 and DOY Le 152:begin;五月
      Kc(Hebei_index)=1.42
      Kc(Beijing_index)=1.42
      Kc(Tianjin_index)=1.42
      Kc(Shandong_index)=1.13
      Kc(Henan_index)=1.29
      Kc(Jiangsu_index)=1.43
      Kc(Anhui_index)=0.87
    end
    DOY Gt 274 and DOY Le 305:begin;十月
      Kc(Hebei_index)=0.85
      Kc(Beijing_index)=0.85
      Kc(Tianjin_index)=0.85
      Kc(Shandong_index)=0.67
      Kc(Henan_index)=0.63
      Kc(Jiangsu_index)=1.14
      Kc(Anhui_index)=1.18
    end
    DOY Gt 305 and DOY Le 335:begin;十一月
      Kc(Hebei_index)=0.92
      Kc(Beijing_index)=0.92
      Kc(Tianjin_index)=0.92
      Kc(Shandong_index)=0.70
      Kc(Henan_index)=0.83
      Kc(Jiangsu_index)=1.14
      Kc(Anhui_index)=1.15
    end
    DOY Gt 335 and DOY Le 365:begin;十二月
      Kc(Hebei_index)=0.54
      Kc(Beijing_index)=0.54
      Kc(Tianjin_index)=0.54
      Kc(Shandong_index)=0.74
      Kc(Henan_index)=0.93
      Kc(Jiangsu_index)=1.19
      Kc(Anhui_index)=1.25
    end
    else:begin
      ;非生育期
      Kc(Hebei_index)= -9999.0
      Kc(Beijing_index)= -9999.0
      Kc(Tianjin_index)= -9999.0
      Kc(Shandong_index)= -9999.0
      Kc(Henan_index)= -9999.0
      Kc(Jiangsu_index)= -9999.0
      Kc(Anhui_index)= -9999.0
    end
  endcase
  return,Kc
end

function CWDI_function,DOY,year,month,day,Et0_path,Kc_path,Pre_list
  ;根据DOY、年、月、日，固定存储的Et0文件夹路径、Kc文件夹路径以及降水list计算DOY日的CWDI数值
  ;Pre_list存有50天的降水数据列表
  year_str = strtrim(string(year),1)
  DOY_str = strtrim(string(DOY),1)
  Today_Kc = Kc_path + 'Kc_'+year_str+'_'+DOY_str+'.tif' ;检索到预测日生成的Kc文件路径
  data_Kc = read_tiff(Today_Kc,geotiff = geotiff_Kc,interleave = 2)
  size_Kc = size(data_Kc,/dim)
  Ncolumn = size_Kc[0]
  Nrow = size_Kc[1]
  DOY_LastYear= (julday(1,1,year)-1)-julday(1,1,year-1)+1;计算去年最后一天的年积日是多少
  Etc_arr = fltarr(Ncolumn,Nrow,50)
  Pre_arr = fltarr(Ncolumn,Nrow,50)
  CWDI = fltarr(size_Kc)

  if DOY Ge 50 then begin;判断年积日是否大于50
    ;当DOY大于50时对etc和pre的累加
    for i=0,49 do begin ;分别读取et0和kc，并相乘为etc存入数组，读入pre存入数组
      ;把etc存到数组etc-arr
      etc = fltarr(size_Kc)
      i_DOY = DOY-i
      i_DOY_str  = strtrim(string(i_DOY),1)
      i_Et0_path = Et0_path + 'Et0_'+year_str+'_'+i_DOY_str+'.tif'
      i_Et0 = read_tiff(i_Et0_path)
      i_Kc_path = Kc_path + 'Kc_'+year_str+'_'+i_DOY_str+'.tif'
      i_Kc = read_tiff(i_Kc_path)
      for r=0, Nrow-1 do begin
        for c=0,Ncolumn-1 do begin
          if i_Et0[c,r] ne -9999.0 then begin
            etc[c,r]=i_Et0[c,r] * i_Kc[c,r]
          endif else begin
            etc[c,r]=-9999.0
          endelse
        endfor
      endfor
      Etc_arr[*,*,i]= etc
      ;把pre存到数组pre_arr
      pre = fltarr(size_Kc)
      i_Pre_path = Pre_list[49-i];往前数第i天，Pre_list是按照日期顺存储50天的降雨文件列表
      i_Pre = read_tiff(i_Pre_path)
      pre = i_Pre
      Pre_arr[*,*,i]= pre
    endfor
  endif else begin
    ;当年积日小于50时，先对0-DOY进行存储 etc和pre，再去存储去年的etc和pr
    ;这是今年的存储pre和etc
    for i=0,DOY-1 do begin
      etc = fltarr(size_Kc)
      i_DOY = DOY-i
      i_DOY_str  = strtrim(string(i_DOY),1)
      i_Et0_path = Et0_path + 'Et0_'+year_str+'_'+i_DOY_str+'.tif'
      i_Et0 = read_tiff(i_Et0_path)
      i_Kc_path = Kc_path + 'Kc_'+year_str+'_'+i_DOY_str+'.tif'
      i_Kc = read_tiff(i_Kc_path)
      for r=0, Nrow-1 do begin
        for c=0,Ncolumn-1 do begin
          if i_Et0[c,r] ne -9999.0 then begin
            etc[c,r]=i_Et0[c,r] * i_Kc[c,r]
          endif else begin
            ;data_Pre[c,r]=-9999.0
            etc[c,r]=-9999.0
          endelse
        endfor
      endfor
      Etc_arr[*,*,i]= etc
      pre = fltarr(size_Kc)
      i_Pre_path = Pre_list[49-i];往前数第i天，
      i_Pre = read_tiff(i_Pre_path)
      pre = i_Pre
      Pre_arr[*,*,i]= pre
    endfor
    ;这是去年的存储pre和etc
    for i=0,49-DOY do begin ;分别读取et0和kc，并相乘并累加
      etc = fltarr(size_Kc)
      i_DOY = DOY_LastYear-i;从上一年的最后一天开始数
      i_DOY_str  = strtrim(string(i_DOY),1)
      lastyear_str = strtrim(string(year-1),1)
      i_Et0_path = Et0_path + 'Et0_'+lastyear_str+'_'+i_DOY_str+'.tif'
      i_Et0 = read_tiff(i_Et0_path)
      i_Kc_path = Kc_path + 'Kc_'+lastyear_str+'_'+i_DOY_str+'.tif'
      i_Kc = read_tiff(i_Kc_path)
      for r=0, Nrow-1 do begin
        for c=0,Ncolumn-1 do begin
          if i_Et0[c,r] ne -9999.0 then begin
            etc[c,r]=i_Et0[c,r] * i_Kc[c,r]
          endif else begin
            ;data_Pre[c,r]=-9999.0
            etc[c,r]=-9999.0
          endelse
        endfor
      endfor
      Etc_arr[*,*,DOY+i]= etc
      pre = fltarr(size_Kc)
      i_Pre_path = Pre_list[49-DOY-i]
      i_Pre = read_tiff(i_Pre_path)
      pre = i_Pre
      Pre_arr[*,*,DOY+i]= pre
    endfor
  endelse
  ;----------结束把Etc和Pre存入两个五十波段的数组里，第一波段表示当天数值，第二波段表示昨天数值--------------
  ;计算 某一时段i_CWDI的值
  ;分别计算10，20，30，40，50时段的cwdi值
  CWDI_10 = fltarr(size_Kc)
  Etc_sum = fltarr(size_Kc)
  Pre_sum = fltarr(size_Kc)
  for i=0,9 do begin
    Etc_sum += Etc_arr[*,*,i]
    Pre_sum += Pre_arr[*,*,i]
  endfor
  for r=0, Nrow-1 do begin
    for c=0,Ncolumn-1 do begin
      if Etc_sum[c,r] eq -9999.0 then begin
        CWDI_10[c,r] = -9999.0
      endif else begin
        if Etc_sum[c,r] lt Pre_sum[c,r] or Etc_sum[c,r] eq 0 then begin
          CWDI_10[c,r] = 0
        endif else begin
          CWDI_10[c,r] = (1 - Pre_sum[c,r] / Etc_sum[c,r]) * 100
        endelse
      endelse
    endfor
  endfor

  CWDI_20 = fltarr(size_Kc)
  Etc_sum = fltarr(size_Kc)
  Pre_sum = fltarr(size_Kc)
  for i=10,19 do begin
    Etc_sum += Etc_arr[*,*,i]
    Pre_sum += Pre_arr[*,*,i]
  endfor
  for r=0, Nrow-1 do begin
    for c=0,Ncolumn-1 do begin
      if Etc_sum[c,r] eq -9999.0 then begin
        CWDI_20[c,r] = -9999.0
      endif else begin
        if Etc_sum[c,r] lt Pre_sum[c,r] or Etc_sum[c,r] eq 0 then begin
          CWDI_20[c,r] = 0
        endif else begin
          CWDI_20[c,r] = (1 - Pre_sum[c,r] / Etc_sum[c,r]) * 100
        endelse
      endelse
    endfor
  endfor

  CWDI_30 = fltarr(size_Kc)
  Etc_sum = fltarr(size_Kc)
  Pre_sum = fltarr(size_Kc)
  for i=20,29 do begin
    Etc_sum += Etc_arr[*,*,i]
    Pre_sum += Pre_arr[*,*,i]
  endfor
  for r=0, Nrow-1 do begin
    for c=0,Ncolumn-1 do begin
      if Etc_sum[c,r] eq -9999.0 then begin
        CWDI_30[c,r] = -9999.0
      endif else begin
        if Etc_sum[c,r] lt Pre_sum[c,r] or Etc_sum[c,r] eq 0 then begin
          CWDI_30[c,r] = 0
        endif else begin
          CWDI_30[c,r] = (1 - Pre_sum[c,r] / Etc_sum[c,r]) * 100
        endelse
      endelse
    endfor
  endfor

  CWDI_40 = fltarr(size_Kc)
  Etc_sum = fltarr(size_Kc)
  Pre_sum = fltarr(size_Kc)
  for i=30,39 do begin
    Etc_sum += Etc_arr[*,*,i]
    Pre_sum += Pre_arr[*,*,i]
  endfor
  for r=0, Nrow-1 do begin
    for c=0,Ncolumn-1 do begin
      if Etc_sum[c,r] eq -9999.0 then begin
        CWDI_40[c,r] = -9999.0
      endif else begin
        if Etc_sum[c,r] lt Pre_sum[c,r] or Etc_sum[c,r] eq 0 then begin
          CWDI_40[c,r] = 0
        endif else begin
          CWDI_40[c,r] = (1 - Pre_sum[c,r] / Etc_sum[c,r]) * 100
        endelse
      endelse
    endfor
  endfor

  CWDI_50 = fltarr(size_Kc)
  Etc_sum = fltarr(size_Kc)
  Pre_sum = fltarr(size_Kc)
  for i=40,49 do begin
    Etc_sum += Etc_arr[*,*,i]
    Pre_sum += Pre_arr[*,*,i]
  endfor
  for r=0, Nrow-1 do begin
    for c=0,Ncolumn-1 do begin
      if Etc_sum[c,r] eq -9999.0 then begin
        CWDI_50[c,r] = -9999.0
      endif else begin
        if Etc_sum[c,r] lt Pre_sum[c,r] or Etc_sum[c,r] eq 0 then begin
          CWDI_50[c,r] = 0
        endif else begin
          CWDI_50[c,r] = (1 - Pre_sum[c,r] / Etc_sum[c,r]) * 100
        endelse
      endelse
    endfor
  endfor

  ;计算CWDI的值
  CWDI = fltarr(size_Kc)
  for r=0, Nrow-1 do begin
    for c=0,Ncolumn-1 do begin
      if CWDI_50[c,r] eq -9999.0 or CWDI_40[c,r] eq -9999.0 or CWDI_30[c,r] eq -9999.0 or CWDI_20[c,r] eq -9999.0 or CWDI_10[c,r] eq -9999.0 then begin
        CWDI[c,r] = -9999.0
      endif else begin
        CWDI[c,r] = CWDI_50[c,r] * 0.1 + CWDI_40[c,r] * 0.15 + CWDI_30[c,r] * 0.2 + CWDI_20[c,r] * 0.25 + CWDI_10[c,r] * 0.3
      endelse
    endfor
  endfor
  return,CWDI
end

function CWDIa_function,DOY,input_file_CWDI,input_file_CWDI_avg,input_file_crop,config_file
  crop_data = read_tiff(input_file_crop,geotiff = geotiff_crop,interleave = 2)
  data_CWDI = read_tiff(input_file_CWDI,geotiff = geotiff_CWDI)
  data_CWDI_avg = read_tiff(input_file_CWDI_avg,geotiff = geotiff_CWDI_avg)
  size_CWDI = size(data_CWDI,/dim)
  Result = fltarr(size_CWDI)
  Ncolumn = size_CWDI[0]
  Nrow = size_CWDI[1]
  data_CWDI_a = fltarr(size_CWDI)
  for r=0, Nrow-1 do begin
    for c=0,Ncolumn-1 do begin
      if data_CWDI_avg[c,r] le 0 then begin
        data_CWDI_a[c,r] = data_CWDI[c,r]
      endif else begin
        data_CWDI_a[c,r] = (data_CWDI[c,r] - data_CWDI_a[c,r])/(1-data_CWDI_a[c,r])* 100
      endelse
    endfor
  endfor
  crop_data_index = where(crop_data Lt 1)

  if config_file eq '' then begin
    case 1 of
      DOY Le 105 and DOY Ge 135 :begin
        Result(where(data_CWDI_a Ge 0  and data_CWDI_a le 35))=1
        Result(where(data_CWDI_a Gt 35 and data_CWDI_a le 50))=2
        Result(where(data_CWDI_a Gt 50 and data_CWDI_a le 65))=3
        Result(where(data_CWDI_a Gt 65 and data_CWDI_a le 80))=4
        Result(where(data_CWDI_a Gt 80 and data_CWDI_a le 100))=5
        Result(crop_data_index)=0

      end
      else:begin
        Result(where(data_CWDI_a Ge 0  and data_CWDI_a le 40))=1
        Result(where(data_CWDI_a Gt 40 and data_CWDI_a le 55))=2
        Result(where(data_CWDI_a Gt 55 and data_CWDI_a le 70))=3
        Result(where(data_CWDI_a Gt 70 and data_CWDI_a le 85))=4
        Result(where(data_CWDI_a Gt 85 and data_CWDI_a le 100))=5
        Result(crop_data_index)=0
      end
    endcase
  endif else begin
    objxml = OBJ_NEW('IDLffXMLDOMDocument',filename = config_file)
    var1 = getvaluebyname(objxml,'threshold1')
    var2 = getvaluebyname(objxml,'threshold2')
    var3 = getvaluebyname(objxml,'threshold3')
    var4 = getvaluebyname(objxml,'threshold4')
    var5 = getvaluebyname(objxml,'threshold5')
    var6 = getvaluebyname(objxml,'threshold6')
    var7 = getvaluebyname(objxml,'threshold7')
    var8 = getvaluebyname(objxml,'threshold8')
    if var1 eq '-99' or var2 eq '-99' or var3 eq '-99' or var4 eq '-99' or var5 eq '-99' or var6 eq '-99' then begin
      re = dialog_message('PARAMETER WRONG!')
      flag_return = -1
    endif
    if var1 ne '-99' then begin
      num_var1 = float(var1)
    endif
    if var2 ne '-99' then begin
      num_var2 = float(var2)
    endif
    if var3 ne '-99' then begin
      num_var3 = float(var3)
    endif
    if var4 ne '-99' then begin
      num_var4 = float(var4)
    endif
    if var5 ne '-99' then begin
      num_var5 = float(var5)
    endif
    if var6 ne '-99' then begin
      num_var6 = float(var6)
    endif
    if var7 ne '-99' then begin
      num_var7 = float(var7)
    endif
    if var8 ne '-99' then begin
      num_var8 = float(var8)
    endif

    case 1 of
      DOY Le 105 and DOY Ge 135 :begin
        Result(where(data_CWDI_a Ge 0  and data_CWDI_a le num_var1))=1
        Result(where(data_CWDI_a Gt num_var1 and data_CWDI_a le num_var2))=2
        Result(where(data_CWDI_a Gt num_var2 and data_CWDI_a le num_var3))=3
        Result(where(data_CWDI_a Gt num_var3 and data_CWDI_a le num_var4))=4
        Result(where(data_CWDI_a Gt num_var4 and data_CWDI_a le 100))=5
        Result(where(crop_data_index))=0

      end
      else:begin
        Result(where(data_CWDI_a Ge 0  and data_CWDI_a le num_var5))=1
        Result(where(data_CWDI_a Gt num_var5 and data_CWDI_a le num_var6))=2
        Result(where(data_CWDI_a Gt num_var6 and data_CWDI_a le num_var7))=3
        Result(where(data_CWDI_a Gt num_var7 and data_CWDI_a le num_var8))=4
        Result(where(data_CWDI_a Gt num_var8 and data_CWDI_a le 100))=5
        Result(where(crop_data_index))=0
      end
    endcase
  endelse
  return,Result
end

pro drought_model_T1,year,month,day,basic_data_listfile,inter_data_folder,Growth_Period_list,T1_tem_listfile,Pre_listfile,config_file,result_output,flag = return_flag
  ;  输入数据分别为最高温度，最低温度，纬度栅格以及输出路径，所有数据应保证相同空间分辨率且行列号应为一致。
  ;  输出数据为输出路径,存储为路径加et0加日序.tif
  
;    year = 2015
;    month = 11
;    day= 2;对应的DOY是306
;    basic_data_listfile = 'D:\wsy\Experiment\HHH\program\test_data\input_test_data\T1\T1_basic_file.txt'
;      ;input_file_LN = 'D:\wsy\Experiment\HHH\program\test_data\input_test_data\LN_hhh.TIF';纬度栅格文件全路径（默认提供）
;      ;input_file_crop ='D:\wsy\Experiment\HHH\program\test_data\input_test_data\Wheat_2018.tif' ;作物分布栅格数据
;      ;input_file_KcProvinceID = 'D:\wsy\Experiment\HHH\program\test_data\input_test_data\Kc_province_ID.TIF';省份索引栅格文件全路径（默认提供）
;    inter_data_folder = 'D:\wsy\Experiment\HHH\program\test_data\input_test_data\T1\T1_inter_data_folder.txt'
;      ;Et0_path = 'D:\wsy\Experiment\HHH\program\test_data\output_test_data\et0_output\';存有实时监测数据生成Et0栅格数据的文件夹，最后应带“\”
;      ;Kc_path = 'D:\wsy\Experiment\HHH\program\test_data\output_test_data\Kc_output\';存有实时监测数据生成Kc栅格数据的文件夹，最后应带“\”
;      ;CWDI_path = 'D:\wsy\Experiment\HHH\program\test_data\output_test_data\CWDI_output\';存有T1生成CWDI栅格数据的文件夹，临时保存T0计算预报的CWDI，最后应带“\”
;      ;CWDI_avg_path = 'D:\wsy\Experiment\HHH\program\test_data\input_test_data\CWDI_avg\';历史CWDI日均值栅格数据存储文件夹，最后应带“\”
;    Growth_Period_list='D:\'
;    T1_tem_listfile = 'D:\wsy\Experiment\HHH\program\test_data\input_test_data\T1\T1_tem_list.txt' ;存有当天预测最高温、最低温栅格数据列表txt文件全路径,1个tmax，1个tmin
;    Pre_listfile='D:\wsy\Experiment\HHH\program\test_data\input_test_data\T1\T1_pre_list.txt';存有50天降水栅格数据列表txt文件全路径
;      config_file = 'D:\wsy\Experiment\HHH\program\test_data\drought_model_T1_config.xml' ;存储在工程文件下，调试时单独指定路径
;    result_output = 'D:\wsy\Experiment\HHH\program\test_data\input_test_data\T1\';T1结果保存路径，最后应带“\”
    
    catch,error_status
    if error_status ne 0 then begin
      re = dialog_message(!error_state.MSG)
      
    endif
    
    ;以上测试用，可删
    
    inter_datapath_list = get_filelist(inter_data_folder) 
    Et0_path = inter_datapath_list[0]
    Kc_path = inter_datapath_list[1]
    CWDI_path = inter_datapath_list[2]
    CWDI_avg_path = inter_datapath_list[3] 
    
    basic_data_list = get_filelist(basic_data_listfile)
    input_file_LN = basic_data_list[0]
    input_file_crop = basic_data_list[1]
    input_file_KcProvinceID = basic_data_list[2]
    
  month = fix(month)
  day =  fix(day)
  year = fix(year)
  Julian = julday(month,day,year) ;儒略日
  DOY= Julian - julday(1,1,year) + 1 ;年积日
  DOY_str = strtrim(string(DOY),1)
  year_str = strtrim(string(year),1)
  
  T1_tem_list = get_filelist(T1_tem_listfile)
  Pre_list = get_filelist(Pre_listfile)
  input_file_Tmax = T1_tem_list[0]
  input_file_Tmin = T1_tem_list[1]
  ;print,input_file_Tmax,input_file_Tmin 
  data_Tmax = read_tiff(input_file_Tmax,geotiff = geotiff_Tmax,interleave = 2)
  ;data_Tmin = read_tiff(input_file_Tmin,geotiff = geotiff_Tmin,interleave = 2)
  
  ;calculation of Et0
  outname = 'Et0_'+year_str+'_'+DOY_str+'.tif'
  et0_output = Et0_path;Et0文件路径即输出路径
  Et0 = Et0_function(input_file_Tmax,input_file_Tmin,input_file_LN,DOY)
  WRITE_TIFF,et0_output+outname, Et0, geotiff = geotiff_Tmax,/float
  print,'Et0计算完成'
  
  ;calculation of Kc
  outname = 'Kc_'+year_str+'_'+DOY_str+'.tif'
  Kc_output = Kc_path
  Kc = Kc_function(DOY,year,month,day,input_file_KcProvinceID) 
  write_tiff,Kc_output+outname,Kc,geotiff = geotiff_Tmax,/float
  print,'Kc计算完成'
  
  ;calculation of CWDI
  CWDI_output = CWDI_path
  outname = 'CWDI_'+year_str+'_'+DOY_str+'.tif'
  CWDI = CWDI_function(DOY,year,month,day,Et0_path,Kc_path,Pre_list)
  write_tiff,CWDI_output+outname,CWDI,geotiff = geotiff_Tmax,/float
  CWDI_result_path = CWDI_output+outname
  print,'CWDI计算完成'
  
  ;calculation of CWDI_a
  outname = 'DroughtModelT1_Result_'+year_str+'_'+DOY_str+'.tif'
  input_file_CWDI_avg = CWDI_avg_path + 'CWDI_avg_'+DOY_str+'.tif'
  result = CWDIa_function(DOY,CWDI_result_path,input_file_CWDI_avg,input_file_crop,config_file)
  write_tiff,result_output+outname,result,geotiff = geotiff_Tmax,/float
  print,'CWDIa计算完成'
 
  catch,/cancel
  
  return_flag = 1
  return
  print,'完成'
end

