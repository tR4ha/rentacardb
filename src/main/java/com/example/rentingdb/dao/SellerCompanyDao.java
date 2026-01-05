package com.example.rentingdb.dao;

import com.example.rentingdb.dto.SellerCompanyDto;

import lombok.RequiredArgsConstructor;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class SellerCompanyDao {

    private final JdbcTemplate jdbc;

    public List<SellerCompanyDto> findAll() {
        return jdbc.query("""
            SELECT company_id, company_name, tax_no, company_email
            FROM seller_company
            ORDER BY company_id
        """, (rs, i) -> {
            SellerCompanyDto dto = new SellerCompanyDto();
            dto.setCompanyId(rs.getLong("company_id"));
            dto.setCompanyName(rs.getString("company_name"));
            dto.setTaxNo(rs.getString("tax_no"));
            dto.setCompanyEmail(rs.getString("company_email"));
            return dto;
        });
    }

    public void insert(SellerCompanyDto dto) {
        jdbc.update("""
            INSERT INTO seller_company (company_name, tax_no, company_email)
            VALUES (?, ?, ?)
        """, dto.getCompanyName(), dto.getTaxNo(), dto.getCompanyEmail());
    }
}
