package com.example.rentingdb.dto;

import lombok.Data;

@Data
public class SellerCompanyDto {
    private Long companyId;
    private String companyName;
    private String taxNo;
    private String companyEmail;
}

