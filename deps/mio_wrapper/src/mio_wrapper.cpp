#include "mio_wrapper.h"
#include <mio/mio.hpp>
#include <memory>
#include <string>
#include <cerrno>
#include <system_error>

// Internal handle structure
struct MioMmapHandle {
    std::unique_ptr<mio::ummap_source> read_mmap;
    std::unique_ptr<mio::ummap_sink> write_mmap;
    MioAccessMode access_mode;
    
    explicit MioMmapHandle(MioAccessMode mode) : access_mode(mode) {}
    
    // Generic method to get data pointer
    const uint8_t* get_data() const {
        if (access_mode == MIO_ACCESS_READ && read_mmap) {
            return read_mmap->data();
        }
        if (access_mode == MIO_ACCESS_WRITE && write_mmap) {
            return write_mmap->data();
        }
        return nullptr;
    }
    
    uint8_t* get_writable_data() {
        if (access_mode == MIO_ACCESS_WRITE && write_mmap) {
            return write_mmap->data();
        }
        return nullptr;
    }
    
    size_t get_size() const {
        if (access_mode == MIO_ACCESS_READ && read_mmap) {
            return read_mmap->size();
        }
        if (access_mode == MIO_ACCESS_WRITE && write_mmap) {
            return write_mmap->size();
        }
        return 0;
    }
    
    size_t get_mapped_length() const {
        if (access_mode == MIO_ACCESS_READ && read_mmap) {
            return read_mmap->mapped_length();
        }
        if (access_mode == MIO_ACCESS_WRITE && write_mmap) {
            return write_mmap->mapped_length();
        }
        return 0;
    }
    
    bool is_open() const {
        if (access_mode == MIO_ACCESS_READ && read_mmap) {
            return read_mmap->is_open();
        }
        if (access_mode == MIO_ACCESS_WRITE && write_mmap) {
            return write_mmap->is_open();
        }
        return false;
    }
    
    bool is_mapped() const {
        if (access_mode == MIO_ACCESS_READ && read_mmap) {
            return read_mmap->is_mapped();
        }
        if (access_mode == MIO_ACCESS_WRITE && write_mmap) {
            return write_mmap->is_mapped();
        }
        return false;
    }
};

// Convert system_error to our error codes
MioError convert_error(const std::error_code& ec) {
    if (!ec) return MIO_SUCCESS;
    
    // Map common error codes using standard error conditions
    if (ec == std::errc::no_such_file_or_directory) {
        return MIO_ERROR_FILE_NOT_FOUND;
    } else if (ec == std::errc::permission_denied) {
        return MIO_ERROR_PERMISSION_DENIED;
    } else if (ec == std::errc::not_enough_memory) {
        return MIO_ERROR_OUT_OF_MEMORY;
    } else if (ec == std::errc::invalid_argument) {
        return MIO_ERROR_INVALID_ARGUMENT;
    } else {
        return MIO_ERROR_UNKNOWN;
    }
}

extern "C" {

MioMmapHandle* mio_mmap_create_from_path(const char* path, 
                                         MioAccessMode access_mode,
                                         size_t offset, 
                                         size_t length, 
                                         MioError* error) {
    if (!path || !error) {
        if (error) *error = MIO_ERROR_INVALID_ARGUMENT;
        return nullptr;
    }
    
    *error = MIO_SUCCESS;
    
    try {
        auto handle = std::make_unique<MioMmapHandle>(access_mode);
        std::error_code ec;
        
        if (access_mode == MIO_ACCESS_READ) {
            // Create read-only mapping directly in unique_ptr
            handle->read_mmap = std::make_unique<mio::ummap_source>(
                mio::make_mmap<mio::ummap_source>(std::string(path), offset, length, ec)
            );
        } else {
            // Create read-write mapping directly in unique_ptr  
            handle->write_mmap = std::make_unique<mio::ummap_sink>(
                mio::make_mmap<mio::ummap_sink>(std::string(path), offset, length, ec)
            );
        }
        
        if (ec) {
            *error = convert_error(ec);
            return nullptr;
        }
        
        return handle.release();
    } catch (const std::exception&) {
        *error = MIO_ERROR_UNKNOWN;
        return nullptr;
    }
}

MioMmapHandle* mio_mmap_create_from_handle(intptr_t file_handle,
                                          MioAccessMode access_mode,
                                          size_t offset,
                                          size_t length,
                                          MioError* error) {
    if (!error) return nullptr;
    
    *error = MIO_SUCCESS;
    
    try {
        auto handle = std::make_unique<MioMmapHandle>(access_mode);
        std::error_code ec;
        
        // Safe conversion from intptr_t to file handle type
        // On Windows: HANDLE (pointer type) - use reinterpret_cast
        // On Unix/Android: int (integer type) - use static_cast
#ifdef _WIN32
        mio::file_handle_type fh = reinterpret_cast<mio::file_handle_type>(file_handle);
#else
        mio::file_handle_type fh = static_cast<mio::file_handle_type>(file_handle);
#endif
        
        if (access_mode == MIO_ACCESS_READ) {
            // Create read-only mapping from handle directly in unique_ptr
            handle->read_mmap = std::make_unique<mio::ummap_source>(
                mio::make_mmap<mio::ummap_source>(fh, offset, length, ec)
            );
        } else {
            // Create read-write mapping from handle directly in unique_ptr
            handle->write_mmap = std::make_unique<mio::ummap_sink>(
                mio::make_mmap<mio::ummap_sink>(fh, offset, length, ec)
            );
        }
        
        if (ec) {
            *error = convert_error(ec);
            return nullptr;
        }
        
        return handle.release();
    } catch (const std::exception&) {
        *error = MIO_ERROR_UNKNOWN;
        return nullptr;
    }
}

const uint8_t* mio_mmap_get_data(MioMmapHandle* handle) {
    return handle ? handle->get_data() : nullptr;
}

uint8_t* mio_mmap_get_data_writable(MioMmapHandle* handle) {
    return handle ? handle->get_writable_data() : nullptr;
}

size_t mio_mmap_get_size(MioMmapHandle* handle) {
    return handle ? handle->get_size() : 0;
}

size_t mio_mmap_get_mapped_length(MioMmapHandle* handle) {
    return handle ? handle->get_mapped_length() : 0;
}

int mio_mmap_is_open(MioMmapHandle* handle) {
    return handle ? (handle->is_open() ? 1 : 0) : 0;
}

int mio_mmap_is_mapped(MioMmapHandle* handle) {
    return handle ? (handle->is_mapped() ? 1 : 0) : 0;
}

MioError mio_mmap_sync(MioMmapHandle* handle) {
    if (!handle) return MIO_ERROR_INVALID_HANDLE;
    
    if (handle->access_mode != MIO_ACCESS_WRITE || !handle->write_mmap) {
        return MIO_ERROR_INVALID_ARGUMENT;
    }
    
    try {
        std::error_code ec;
        handle->write_mmap->sync(ec);
        return convert_error(ec);
    } catch (const std::exception&) {
        return MIO_ERROR_UNKNOWN;
    }
}

void mio_mmap_destroy(MioMmapHandle* handle) {
    if (handle) {
        delete handle;
    }
}

const char* mio_get_error_message(MioError error) {
    switch (error) {
        case MIO_SUCCESS:
            return "Success";
        case MIO_ERROR_INVALID_ARGUMENT:
            return "Invalid argument";
        case MIO_ERROR_FILE_NOT_FOUND:
            return "File not found";
        case MIO_ERROR_PERMISSION_DENIED:
            return "Permission denied";
        case MIO_ERROR_OUT_OF_MEMORY:
            return "Out of memory";
        case MIO_ERROR_MAPPING_FAILED:
            return "Memory mapping failed";
        case MIO_ERROR_INVALID_HANDLE:
            return "Invalid handle";
        case MIO_ERROR_UNKNOWN:
        default:
            return "Unknown error";
    }
}

} // extern "C"
