package com.example.rentingdb.service;

import com.example.rentingdb.dao.SellerCompanyDao;
import com.example.rentingdb.dto.SellerCompanyDto;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SellerCompanyService {

    private final SellerCompanyDao dao;

    public List<SellerCompanyDto> getAll() {
        return dao.findAll();
    }

    public void create(SellerCompanyDto dto) {
        dao.insert(dto);
    }
}

