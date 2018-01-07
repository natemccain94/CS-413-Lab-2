@ Nate McCain, Lab Two, Newman

@ output messages
.data

welcomeMessage: .asciz "Welcome customer %d! Please enter an amount to withdraw.\n"
secondWelcomeMessage: .asciz "You must withdraw an amount less than $200 and divisible by 10.\n"

valueTooHighMessage: .asciz "The amount you entered is too high.\n"
valueTooLowMessage: .asciz "The amount you entered is too low.\n"
valueNotDivMessage: .asciz "The amount you entered is not divisible by 10.\n"
notEnoughBillsMessage: .asciz "The amount you entered is not possible with current inventory.\n"

emptyMessage: .asciz "The ATM is empty. Goodnight!\n"
goodnightMessage: .asciz "This ATM has served 10 customers. Goodnight! \n"
goodnightTwoMessage: .asciz "This ATM is empty. Goodnight!\n"

haveValueTwentyMessage: .asciz "Dispensing %d twenty dollar bill(s). \n"
haveValueTenMessage: .asciz "Dispensing %d ten dollar bill(s). \n"

nextCustomer: .asciz "Next customer please!\n"

num: .word 0
userInput: .asciz "%d"


@ declaring the other stuff

.text
    .global main
    .extern printf
    .extern scanf

@ Start of the main function

main:
    MOV R4, #1  @ The customer number.
    MOV R5, #50 @ The number of $20 bills in inventory.
    MOV R6, #50 @ The number of $10 bills in inventory.
    B control


@ Acts as a while loop for the ATM operation. While 10 customers have not been
@ served and the ATM is not empty, continue inside this function.
control:

    MOV R7, #0  @ The number of $20 bills needed to make the withdrawal.
    MOV R9, #0 @ The number of $10 bills needed to make the withdrawal.

    CMP R4, #11     @ Check to see if 10 customers have been helped.
    BEQ closeShop   @ Close up shop if the above condition has been met.
    CMP R5, #0  @ Check the inventory of $20's.
    ADDEQ R6, R6, R5    @ If ATM is out of 20's, check to see if it is out of 10's.
    CMP R6, #0  @ Compare the inventory of $10's
    BEQ closeShopTwo @ Close the ATM because the inventory is empty.

    @ Print the welcome message. R4=customer number.
    MOV R1, R4
    LDR R0, =welcomeMessage
    BL printf
    @ Print the second welcome message.
    LDR R0, =secondWelcomeMessage
    BL printf

    @ Get the customer's input
    sub sp, sp, #4

    MOV R1, sp
    LDR R0, =userInput
    BL scanf
    ldr R1, [sp]
    @ Put the customer's input in R8.
    MOV R8, R1

    @ If the input is greater than 200, print error message, go to next customer.
    CMP R8, #200
    BGT valueTooHigh
    @ If the input is less than 10, print error message, go to next customer.
    CMP R8, #10
    BLT valueTooLow

    @ Check to make sure the amount is divisible by 10 (possible to dispense).
    MOV R10, R8     @ Store the amount in R10
    B validValueCheck  @ Checks to see if the amount is possible to dispense.


@--------------------------------------------------------------------------------------------------------------------------
@ This function checks to see if the value entered by the customer is divisible by 10.
@ If it is not, increment the customer number and branch to the beginning of the control function.
validValueCheck:
    CMP R10, #0             @ If the value is divisible by 10
    MOVEQ R10, R8           @ Reset R10 to the value of R8 and
    BEQ divideByTwenty      @ Branch to determining how to dispense the amount
    CMP R10, #10            @ If the value is not divisible by 10
    BLT valueNotDivisible   @ Print error message, go to next customer.

    @ If the above things are not having issues, then subtract 10 from the current value.
    SUB R10, R10, #10   @ Subtract 10 from the amount.
    B validValueCheck   @ return to the top of the loop.
@--------------------------------------------------------------------------------------------------------------------------
@ This function finds the number of $20 bills that can be used to make up the amount.
@ This function is only reached if the ATM knows the customer's withdrawal amount is
@ divisible by 10.
@ R7= number of $20 bills inside the withdrawal amount.
@ R10 holds the modified amount
divideByTwenty:
    CMP R10, #20            @ If R10 is greater than 20,
    SUBGT R10, R10, #20     @ subtract 20 from r10.
    ADDGT R7, R7, #1        @ Then increment the counter for the amount of 20's needed.

    CMP R10, #20            @ If R10 is equal to 20,
    SUBEQ R10, R10, #20     @ subtract 20 from r10.
    ADDEQ R7, R7, #1        @ Then increment the counter for the amount of 20's needed.
    BEQ checkTwentyCount    @ Go to function to determine if we have enough 20's for the amount calculated.

    CMP R10, #20            @ If R10 is less than 20 and not equal to zero
    BLT checkTwentyCount    @ then go to function to determine if we have enough 20's for the amount calculated.

    B divideByTwenty        @ Return to the top of this loop.
@--------------------------------------------------------------------------------------------------------------------------
@ This function checks to see if we have enough $20 bills to dispense to the customer.
@ The value of R9 ($20 bills needed for withdrawal) is checked against the value of R5 ($20 bills in inventory).
@ The amount of $20 bills in inventory is not changed until we can actually dispense to the customer.
@ If there are not enough bills in inventory, the amount in R9 is changed to what is available.
@ After the calculations against inventory are made, R10 is given the value of R8, and then is adjusted to whatever value
@ is available.
checkTwentyCount:
    CMP R5, R7        @ If the inventory levels are less than what is needed, we make the adjustments.
    MOVLT R7, R5      @ R9 now holds whatever is left in the inventory.
    MOVLT R2, #20     @ r2 now holds 20 for the multiplication instruction
    MULLT R1, R7, R2   @ R1 now holds the amount to be subtracted from the total.
    SUBLT R10, R8, R1 @ R10 now holds the value after the amount of available $20 bills are dispensed.

    @ If the inventory levels are greater than equal to what is needed, or if the above has been executed,
    @ we now branch to the function that divides the remainder by 10.
    B divideByTen
@--------------------------------------------------------------------------------------------------------------------------
@ This function finds the number of $10 bills that can be used to make up the amount.
@ This function is reached after calculating the number of $20 bills that can be dispensed
@ in the current transaction.
@ R10= remaining value after $20 bills have been removed from total.
@ R9= number of $10 bills needed for the transaction.
divideByTen:
    CMP R10, #0         @ If the number of $10 has been counted,
    BEQ checkTenCount   @ then check the inventory to see if the transaction is possible.

    SUB R10, R10, #10   @ Else, subtract $10 from the remaining value
    ADD R9, R9, #1    @ and increment the counter for $10 bills needed.

    B divideByTen       @ Return to the top of this loop.
@--------------------------------------------------------------------------------------------------------------------------
@ This function checks to see if we have enough $10 bills to dispense to the customer.
@ The value of R9 ($10 bills needed for withdrawal) is checked against the value of R6 ($10 bills in inventory).
@ If there are enough bills in inventory, branch to successful transaction function.
@ else, print error message, not enough bills in ATM for transaction. Next customer!
checkTenCount:
    CMP R6, R9     @ If there are enough $10 bills in inventory,
    BGE successfulTransaction   @ print out the transaction result and adjust inventory

    B notEnoughBills    @ Else, error message, next customer.
@--------------------------------------------------------------------------------------------------------------------------
@ This function prints out the error message for if the value a customer wishes to withdraw is over $200.
valueTooHigh:

    LDR R0, =valueTooHighMessage
    BL printf

    ADD R4, R4, #1  @ Increment the customer number.

    CMP R4, #11     @ If 10 customers have not been helped,
    LDR R0, =nextCustomer   @ ask for the next customer.
    BLLT printf

    B control   @ Return to the top of the control function.
@--------------------------------------------------------------------------------------------------------------------------
@ This function prints out the error message for if the value a customer wishes to withdraw is less than $10.
valueTooLow:

    LDR R0, =valueTooLowMessage
    BL printf
    ADD R4, R4, #1  @ Increment the customer number.

    CMP R4, #11     @ If 10 customers have not been helped,
    LDR R0, =nextCustomer   @ ask for the next customer.
    BLLT printf

    B control   @ Return to the top of the control function.
@--------------------------------------------------------------------------------------------------------------------------
@ This function prints out the error message for if the value a customer wishes to withdraw is not divisible by 10.
valueNotDivisible:
    LDR R0, =valueNotDivMessage
    BL printf
    ADD R4, R4, #1  @ Increment the customer number.

    CMP R4, #11     @ If 10 customers have not been helped,
    LDR R0, =nextCustomer @ ask for the next customer.
    BLLT printf

    B control   @ Return to the top of the control function.
@--------------------------------------------------------------------------------------------------------------------------
@ This function prints out the error message for if the value a customer wishes to withdraw is not possible
@ due to the ATM not having enough bills in inventory.
notEnoughBills:
    LDR R0, =notEnoughBillsMessage
    BL printf
    ADD R4, R4, #1  @ Increment the customer number.

    CMP R4, #11     @ If 10 customers have not been helped,
    LDR R0, =nextCustomer   @ ask for the next customer.
    BLLT printf

    B control   @ Return to the top of the control function.
@--------------------------------------------------------------------------------------------------------------------------
@ This function prints out the amount dispensed if the ATM can make the transaction.
@ R5 ($20 bills inventory) is decreased by the number in R7 ($20 bills in the transaction).
@ R6 ($10 bills inventory) is decreased by the number in R9 ($10 bills in the transaction).
@ After printing the transaction, the function branches to the top of the control function.
successfulTransaction:
    SUB R5, R5, R7      @ Adjust the inventory of $20 bills.
    SUB R6, R6, R9     @ Adjust the inventory of $10 bills.

    @ Print the number of $20 bills dispensed.
    MOV R1, R7
    LDR R0, =haveValueTwentyMessage
    BL printf
    @ Print the number of $10 bills dispensed
    MOV R1, R9
    LDR R0, =haveValueTenMessage
    BL printf

    ADD R4, R4, #1  @ Increment the customer number.
    CMP R4, #11     @ If 11 customers have not been helped,
    LDR R0, =nextCustomer   @ ask for the next customer.
    BLLT printf

    B control   @ Return to the top of the control function.
@--------------------------------------------------------------------------------------------------------------------------
@ This function closes the ATM if the inventory is empty.
closeShopTwo:
    LDR R0, =goodnightTwoMessage
    BL printf
    MOV R0, #0
    MOV R7, #1
    SVC 0

@--------------------------------------------------------------------------------------------------------------------------
@ This function closes the ATM if it has interacted with 10 customers.
closeShop:
    LDR R0, =goodnightMessage
    BL printf
    MOV R0, #0
    MOV R7, #1
    SVC 0
    .end
