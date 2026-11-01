%dw 2.0
output application/json

var demographics = payload.demographics default {}
var accountsList = payload.accounts default []
var totalBalance = sum(accountsList.balance default [0])

fun determineCustomerType(balance: Number) = 
    if (balance >= 100000) "A"
    else if (balance >= 25000) "B"
    else if (balance >= 5000) "C"
    else "D"

var cType = determineCustomerType(totalBalance)

fun getTierName(cType: String) = cType match {
    case "A" -> "Platinum / High Net Worth"
    case "B" -> "Gold / Affluent"
    case "C" -> "Silver / Mass Market"
    case "D" -> "Bronze / Starter"
    else     -> "Standard"
}

fun getTierBenefits(cType: String) = cType match {
    case "A" -> [
        "Dedicated Relationship Manager",
        "Zero International Wire Fees",
        "Exclusive Investment Advisory",
        "Unlimited Airport Lounge Access"
    ]
    case "B" -> [
        "Priority Customer Support",
        "Discounted Forex Rates",
        "Quarterly Financial Health Checkup",
        "Credit Card Annual Fee Waiver"
    ]
    case "C" -> [
        "Standard Online Banking",
        "Free Mobile Alerts",
        "Zero Monthly Maintenance Fee with Minimum Balance"
    ]
    case "D" -> [
        "Basic Savings Account",
        "Digital Debit Card",
        "Self-Service Mobile Banking"
    ]
    else -> ["Standard Banking Access"]
}
---
{
    customerId: demographics.customerId default payload.customerId,
    fullName: (demographics.firstName default "") ++ " " ++ (demographics.lastName default ""),
    demographics: demographics,
    accounts: accountsList,
    financialSummary: {
        totalAccounts: sizeOf(accountsList),
        totalBalance: totalBalance as Number {format: "#.00"},
        currency: (accountsList[0].currency) default "USD"
    },
    classification: {
        customerType: cType,
        tierName: getTierName(cType),
        tierBenefits: getTierBenefits(cType),
        evaluatedAt: now()
    }
}
