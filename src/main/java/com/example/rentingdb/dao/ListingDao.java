package com.example.rentingdb.dao;

import com.example.rentingdb.dto.ListingDto;

import lombok.RequiredArgsConstructor;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class ListingDao {

    private final JdbcTemplate jdbc;

    public List<ListingDto> findAll() {
        return jdbc.query("""
            SELECT
              l.listing_id,
              l.title,
              sc.company_name,
              COALESCE(v.plate_no, vc.class_name) AS target,
              l.active
            FROM listing l
            JOIN seller_company sc ON sc.company_id = l.company_id
            LEFT JOIN vehicle v ON v.vehicle_id = l.vehicle_id
            LEFT JOIN vehicle_class vc ON vc.class_id = l.class_id
            ORDER BY l.listing_id
        """, (rs, i) -> {
            ListingDto dto = new ListingDto();
            dto.setListingId(rs.getLong("listing_id"));
            dto.setTitle(rs.getString("title"));
            dto.setCompanyName(rs.getString("company_name"));
            dto.setTarget(rs.getString("target"));
            dto.setActive(rs.getBoolean("active"));
            return dto;
        });
    }
}
