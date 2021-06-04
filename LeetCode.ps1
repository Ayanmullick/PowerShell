(1..15)|%{$a = ""; if($_%3 -eq 0){$a +='Fizz'};if($_%5 -eq 0){$a+='Buzz'};if($a -eq ""){$a =$_}; $a} #412| FizBuzz|https://leetcode.com/problems/fizz-buzz/
