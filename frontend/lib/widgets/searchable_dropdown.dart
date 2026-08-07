import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SearchableDropdown extends StatefulWidget {
  final String hint;
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onApply;
  final bool isMultiSelect;
  final bool showSearch;
  final String secondaryButtonText;

  const SearchableDropdown({
    super.key,
    required this.hint,
    required this.options,
    required this.selectedValues,
    required this.onApply,
    this.isMultiSelect = true,
    this.showSearch = true,
    this.secondaryButtonText = 'Reset',
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen) {
      _tempSelected = List.from(widget.selectedValues);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _tempSelected = List.from(widget.selectedValues);
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _applySelection() {
    widget.onApply(List.from(_tempSelected));
    _removeOverlay();
  }

  void _resetSelection(StateSetter setOverlayState) {
    setOverlayState(() {
      _tempSelected.clear();
    });
  }

  void _showOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              width: 320, // Slightly wider to match LinkedIn style
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 8),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      final filteredOptions = widget.options
                          .where((o) => o.toLowerCase().contains(_searchQuery.toLowerCase()))
                          .toList();

                      return Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Search and Close
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 8),
                              child: Row(
                                children: [
                                  if (widget.showSearch)
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        autofocus: true,
                                        onChanged: (val) {
                                          setOverlayState(() {
                                            _searchQuery = val;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Add a ${widget.hint.toLowerCase().replaceAll("any ", "")}',
                                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            borderSide: const BorderSide(color: AppColors.borderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            borderSide: const BorderSide(color: AppColors.borderColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            borderSide: const BorderSide(color: Colors.blue),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20, color: AppColors.onSurfaceVariant),
                                    onPressed: _removeOverlay,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Scrollable list of checkboxes
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: filteredOptions.length,
                                itemBuilder: (context, index) {
                                  final option = filteredOptions[index];
                                  final isSelected = _tempSelected.contains(option);
                                  return InkWell(
                                    onTap: () {
                                      setOverlayState(() {
                                        if (widget.isMultiSelect) {
                                          if (isSelected) {
                                            _tempSelected.remove(option);
                                          } else {
                                            _tempSelected.add(option);
                                          }
                                        } else {
                                          _tempSelected = [option];
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: widget.isMultiSelect 
                                              ? Checkbox(
                                                  value: isSelected,
                                                  onChanged: (val) {
                                                    setOverlayState(() {
                                                      if (val == true) {
                                                        _tempSelected.add(option);
                                                      } else {
                                                        _tempSelected.remove(option);
                                                      }
                                                    });
                                                  },
                                                  activeColor: const Color(0xFF0A66C2),
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                )
                                              : Radio<String>(
                                                  value: option,
                                                  groupValue: _tempSelected.isNotEmpty ? _tempSelected.first : null,
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      setOverlayState(() {
                                                        _tempSelected = [val];
                                                      });
                                                    }
                                                  },
                                                  activeColor: const Color(0xFF0A66C2),
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: const TextStyle(
                                                color: AppColors.onSurface,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // Footer with Reset and Show results
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.borderColor)),
                                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _resetSelection(setOverlayState),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.onSurfaceVariant,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    child: Text(widget.secondaryButtonText, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _applySelection,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0A66C2), // LinkedIn blue
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: const Text('Show results', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selectedValues.isNotEmpty;
    
    // Determine the label text
    String labelText = widget.hint;
    if (hasSelection) {
      if (widget.selectedValues.length == 1) {
        labelText = widget.selectedValues.first;
      } else {
        // e.g. "Company" without "Any"
        labelText = widget.hint.replaceAll("Any ", "");
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: hasSelection ? const Color(0xFF057642) : Colors.white, // LinkedIn green for selected state
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasSelection ? const Color(0xFF057642) : AppColors.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labelText,
                style: TextStyle(
                  color: hasSelection ? Colors.white : AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasSelection) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${widget.selectedValues.length}',
                    style: const TextStyle(
                      color: Color(0xFF057642),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: hasSelection ? Colors.white : AppColors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
