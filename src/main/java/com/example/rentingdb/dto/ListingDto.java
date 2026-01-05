package com.example.rentingdb.dto;

import lombok.Data;

@Data
public class ListingDto {
    private Long listingId;
    private String title;
    private String companyName;
    private String target; // plate_no veya class_name
    private Boolean active;
}
