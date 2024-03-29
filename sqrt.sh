#!/bin/bash
function testCode {
printf '%s\n' \
'#include <crap/algorithm>                                                                                      ' \
'#include <crap/cmath>                                                                                          ' \
'#include <crap/numbers>                                                                                        ' \
'#include <crap/numeric>                                                                                        ' \
'#include <crap/ratio>                                                                                          ' \
'#include <crap/utility>                                                                                        ' \
'#include <cstddef>                                                                                             ' \
'                                                                                                               ' \
'using valueType = std :: int64_t;                                                                              ' \
"using step = crap :: valueRatio<valueType, '+', STEP_NUM, STEP_DEN>;                                           " \
"using init = crap :: valueRatio<valueType, '+', INIT_NUM, INIT_DEN>;                                           " \
'constexpr const std :: size_t steps = 99u;                                                                     ' \
'                                                                                                               ' \
'template <class ... Elements> using transformation = crap :: transformType<crap :: sqrtType, Elements...>;     ' \
'template <class ... Elements> using addition =                                                                 ' \
'	crap :: partialSumType<crap :: plusType, Elements...>;                                                  ' \
'                                                                                                               ' \
'template <class ... Elements> using addInit = crap :: copyType<init, Elements...>;                             ' \
'                                                                                                               ' \
'template <class Element> struct toDouble                                                                       ' \
'{                                                                                                              ' \
' using value_type = const long double;                                                                         ' \
" constexpr static value_type value = ((Element :: sign == '+') ? 1.0l : (-1.0l)) *                             " \
'	 (static_cast<value_type>(Element :: num) / static_cast<value_type>(Element :: den));                   ' \
'};                                                                                                             ' \
'                                                                                                               ' \
'template <class ... Elements> struct arrayer                                                                   ' \
'{                                                                                                              ' \
' constexpr const static long double array[sizeof...(Elements)] = {(toDouble <Elements> :: value)...};          ' \
'};                                                                                                             ' \
'                                                                                                               ' \
'template <class ... Elements> constexpr const long double arrayer <Elements...> :: array[sizeof...(Elements)]; ' \
'                                                                                                               ' \
'using X = typename crap :: reproduceType <steps, step> :: template type <addInit> :: template type<addition>;  ' \
'using xArrayer = typename X :: template type<arrayer>;                                                         ' \
'using yArrayer = typename X :: template type <transformation> :: template type<arrayer>;                       ' \
'                                                                                                               ' \
'#include <algorithm>                                                                                           ' \
'#include <cstdlib>                                                                                             ' \
'#include <iostream>                                                                                            ' \
'#include <iterator>                                                                                            ' \
'#include <limits>                                                                                              ' \
'#include <sstream>                                                                                             ' \
'#include <string>                                                                                              ' \
'#define NAME_GENERATOR(i_n, i_d, s_n, s_d) generate_init##i_n##over##i_d##_step##s_n##over##s_d                ' \
'#define NAME(i_n, i_d, s_n, s_d) NAME_GENERATOR(i_n, i_d, s_n, s_d)                                            ' \
'                                                                                                               ' \
'void NAME(INIT_NUM, INIT_DEN, STEP_NUM, STEP_DEN)()                                                            ' \
'{                                                                                                              ' \
' std :: stringstream stream("", std :: ios_base :: out | std :: ios_base :: ate);                              ' \
' std :: transform(std :: begin(xArrayer :: array), std :: end(xArrayer :: array),                              ' \
'		 std :: begin(yArrayer :: array),                                                               ' \
'		 std :: ostream_iterator<std :: string>(std :: cout, "\n"),                                     ' \
'		 [&stream](const auto& x, const auto& y) -> std :: string                                       ' \
'		 {                                                                                              ' \
'		  stream.str("");                                                                               ' \
'		  stream.precision(std :: numeric_limits <long double> :: max_digits10);                        ' \
"		  stream << x << ' ' << y;                                                                      " \
'		  return stream.str();                                                                          ' \
'		 });                                                                                            ' \
' std :: cout << std :: flush;                                                                                  ' \
'}                                                                                                              '
}

init_ns=(  0   1   2   3   4   5   6   7   8   9 10 20 30 40 50 60 70 80 90)
init_ds=(  1   1   1   1   1   1   1   1   1   1  1  1  1  1  1  1  1  1  1)
step_ns=(  1   1   1   1   1   1   1   1   1   1  1  1  1  1  1  1  1  1  1)
step_ds=(100 100 100 100 100 100 100 100 100 100 10 10 10 10 10 10 10 10 10)

function unitName {
 printf 'testCode_init%dover%d_step%dover%d.o ' ${init_ns[$1]} ${init_ds[$1]} ${step_ns[$1]} ${step_ds[$1]}
}

function generateFunctionName {
 printf 'generate_init%dover%d_step%dover%d();' ${init_ns[$1]} ${init_ds[$1]} ${step_ns[$1]} ${step_ds[$1]}
}

function appendToHeader {
 printf 'void %s\n' $(generateFunctionName $1) >> testCode.hpp
}

function initialiseMain {
 printf '%s\n' \
	'#include <cstdlib>     ' \
	'#include "testCode.hpp"' \
	'                       ' \
	'int main()             ' \
	'{                      ' > testMain.cpp
}

function closeMain {
 printf '%s\n' \
	'return EXIT_SUCCESS;' \
	'}                   ' >> testMain.cpp
 clang++ -o testMain.o -c testMain.cpp
}

function appendToMain {
 printf '%s\n' $(generateFunctionName $1) >> testMain.cpp
}

function generateUnit {
 init_num=${init_ns[$1]}
 init_den=${init_ds[$1]}
 step_num=${step_ns[$1]}
 step_den=${step_ds[$1]}
 [ ! -f "testCode.cpp" ] && (testCode > testCode.cpp)
 [ ! -f "testMain.cpp" ] && initialiseMain
 appendToMain $1
 appendToHeader $1
 clang++ -o $(unitName $1) -I ~/crap/include -D INIT_NUM=$init_num -D INIT_DEN=$init_den -D STEP_NUM=$step_num -D STEP_DEN=$step_den -c testCode.cpp &
}

unitNames=()

while getopts j:h: flag
do
 case "${flag}" in
  j) threadNum=${OPTARG};;
  h) printHelp=true;;
 esac
done

for i in $(seq `expr ${#init_ns[@]} - 1`)
do
 generateUnit $i
 unitNames+=$(unitName $i)
 if ! [ -z ${threadNum+default} ]; then
  [[ $threadNum -ne 0 ]] && [[ `expr $i % $threadNum` -eq 0 ]] && wait;
 fi
done
closeMain
wait
clang++ -o ~/gnuplotTests/testCode testMain.o ${unitNames[*]}
for i in $(seq `expr ${#init_ns[@]} - 1`)
do
 rm -f $(unitName $i)
done
rm -f testCode.cpp
rm -f testCode.hpp
rm -f testMain.cpp
