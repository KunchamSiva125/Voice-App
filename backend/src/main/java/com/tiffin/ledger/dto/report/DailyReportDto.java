package com.tiffin.ledger.dto.report;

import java.time.LocalDate;

public class DailyReportDto {
    private LocalDate businessDate;
    private long totalCreditsRecordedPaise;
    private double totalCreditsInRupees;
    private long totalPaymentsCollectedPaise;
    private double totalPaymentsInRupees;
    private long totalDiscountsPaise;
    private double totalDiscountsInRupees;
    private long netChangePaise;
    private double netChangeInRupees;
    private long totalOutstandingDebtPaise;
    private double totalOutstandingDebtInRupees;
    private long activeCustomersCount;
    private long transactionsCountToday;
    private String teluguSummary;

    public DailyReportDto() {}

    public LocalDate getBusinessDate() { return businessDate; }
    public void setBusinessDate(LocalDate businessDate) { this.businessDate = businessDate; }

    public long getTotalCreditsRecordedPaise() { return totalCreditsRecordedPaise; }
    public void setTotalCreditsRecordedPaise(long totalCreditsRecordedPaise) {
        this.totalCreditsRecordedPaise = totalCreditsRecordedPaise;
        this.totalCreditsInRupees = totalCreditsRecordedPaise / 100.0;
    }

    public double getTotalCreditsInRupees() { return totalCreditsInRupees; }
    public void setTotalCreditsInRupees(double totalCreditsInRupees) { this.totalCreditsInRupees = totalCreditsInRupees; }

    public long getTotalPaymentsCollectedPaise() { return totalPaymentsCollectedPaise; }
    public void setTotalPaymentsCollectedPaise(long totalPaymentsCollectedPaise) {
        this.totalPaymentsCollectedPaise = totalPaymentsCollectedPaise;
        this.totalPaymentsInRupees = totalPaymentsCollectedPaise / 100.0;
    }

    public double getTotalPaymentsInRupees() { return totalPaymentsInRupees; }
    public void setTotalPaymentsInRupees(double totalPaymentsInRupees) { this.totalPaymentsInRupees = totalPaymentsInRupees; }

    public long getTotalDiscountsPaise() { return totalDiscountsPaise; }
    public void setTotalDiscountsPaise(long totalDiscountsPaise) {
        this.totalDiscountsPaise = totalDiscountsPaise;
        this.totalDiscountsInRupees = totalDiscountsPaise / 100.0;
    }

    public double getTotalDiscountsInRupees() { return totalDiscountsInRupees; }
    public void setTotalDiscountsInRupees(double totalDiscountsInRupees) { this.totalDiscountsInRupees = totalDiscountsInRupees; }

    public long getNetChangePaise() { return netChangePaise; }
    public void setNetChangePaise(long netChangePaise) {
        this.netChangePaise = netChangePaise;
        this.netChangeInRupees = netChangePaise / 100.0;
    }

    public double getNetChangeInRupees() { return netChangeInRupees; }
    public void setNetChangeInRupees(double netChangeInRupees) { this.netChangeInRupees = netChangeInRupees; }

    public long getTotalOutstandingDebtPaise() { return totalOutstandingDebtPaise; }
    public void setTotalOutstandingDebtPaise(long totalOutstandingDebtPaise) {
        this.totalOutstandingDebtPaise = totalOutstandingDebtPaise;
        this.totalOutstandingDebtInRupees = totalOutstandingDebtPaise / 100.0;
    }

    public double getTotalOutstandingDebtInRupees() { return totalOutstandingDebtInRupees; }
    public void setTotalOutstandingDebtInRupees(double totalOutstandingDebtInRupees) { this.totalOutstandingDebtInRupees = totalOutstandingDebtInRupees; }

    public long getActiveCustomersCount() { return activeCustomersCount; }
    public void setActiveCustomersCount(long activeCustomersCount) { this.activeCustomersCount = activeCustomersCount; }

    public long getTransactionsCountToday() { return transactionsCountToday; }
    public void setTransactionsCountToday(long transactionsCountToday) { this.transactionsCountToday = transactionsCountToday; }

    public String getTeluguSummary() { return teluguSummary; }
    public void setTeluguSummary(String teluguSummary) { this.teluguSummary = teluguSummary; }
}
