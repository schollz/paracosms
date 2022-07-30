local utils={}

function utils.fromhex(str)
  return (str:gsub('..',function (cc)
    return string.char(tonumber(cc,16))
  end))
end

function utils.tohex(str)
  return (str:gsub('.',function (c)
    return string.format('%02X',string.byte(c))
  end))
end

function utils.lcm(arr)
  if #arr==1 then
    do return arr[1] end
  elseif #arr==0 then
    do return end
  end
  local all_nonzero=true
  for _,v in ipairs(arr) do
    if v==0 then
      all_nonzero=false
    end
  end
  if not all_nonzero then
    do return end
  end
  local lcm_=function(num1,num2)
    if (num1>num2) then
      num=num1
      den=num2
    else
      num=num2
      den=num1
    end
    rem=num%den
    while (rem~=0) do
      num=den
      den=rem
      rem=num%den
    end
    gcd=den
    lcm=math.floor(math.floor(num1*num2)/math.floor(gcd))
    return lcm
  end

  local l=lcm_(arr[1],arr[2])
  for i,v in ipairs(arr) do
    if i>2 then
      l=lcm_(l,v)
    end
  end
  return l
end

return utils
