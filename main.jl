print("What is your name? \n")

name = readline()

add(x,y) = x + y
sub(x,y) = x-y
mul(x,y) = x*y
div(x,y) = x/y

if name == "John"
    print("You are BANNED!")
    wait(3)
    exit()
else
    print("Input two numbers, seperated by a space \n")
    num1, num2 = split(readline(), " ")
    num1 = parse(Int, num1)
    num2 = parse(Int, num2)
    print("What operation would you like? \n")
    op = lowercase(readline())
    if op == "add"
        add(num1, num2)
    elseif op == "sub"
        sub(num1, num2)
    elseif op == "multiply"
        mul(num1, num2)
    elseif op == "division"
        div(num1, num2)
    else
        print("Try again...")
    end
end