(1..15)|%{$a = ""; if($_%3 -eq 0){$a +='Fizz'};if($_%5 -eq 0){$a+='Buzz'};if($a -eq ""){$a =$_}; $a} #412| FizBuzz|https://leetcode.com/problems/fizz-buzz/

1..15|%{@("Fizz")[$_%3]+{Buzz}[$_%5]??$_} #v2: https://youtu.be/j3iuoxmZ6sY?list=PLfeA8kIs7Cof3Ev-KGonHLdFh8joxDFdW&t=3450
