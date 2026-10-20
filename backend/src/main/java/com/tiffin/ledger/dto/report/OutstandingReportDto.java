package com.tiffin.ledger.dto.report;

import java.util.ArrayList;
import java.util.List;

public class OutstandingReportDto {
    private long totalOutstandingDebtPaise;
    private double totalOutstandingDebtInRupees;
    private long totalDebtorsCount;
    private List<TopDebtorDto> topDebtors = new ArrayList<>();

    public OutstandingReportDto() {}

    public long getTotalOutstandingDebtPaise() { return totalOutstandingDebtPaise; }
    public void setTotalOutstandingDebtPaise(long totalOutstandingDebtPaise) {
        this.totalOutstandingDebtPaise = totalOutstandingDebtPaise;
        this.totalOutstandingDebtInRupees = totalOutstandingDebtPaise / 100.0;
    }

    public double getTotalOutstandingDebtInRupees() { return totalOutstandingDebtInRupees; }
    public void setTotalOutstandingDebtInRupees(double totalOutstandingDebtInRupees) { this.totalOutstandingDebtInRupees = totalOutstandingDebtInRupees; }

    public long getTotalDebtorsCount() { return totalDebtorsCount; }
    public void setTotalDebtorsCount(long totalDebtorsCount) { this.totalDebtorsCount = totalDebtorsCount; }

    public List<TopDebtorDto> getTopDebtors() { return topDebtors; }
    public void setTopDebtors(List<TopDebtorDto> topDebtors) {
        this.topDebtors = topDebtors != null ? topDebtors : new ArrayList<>();
    }
}
